import Foundation
import FirebaseFirestore

final class ParamedicEmergencyRepository {
    
    static let shared = ParamedicEmergencyRepository()
    
    private let firestoreService: FirestoreService
    
    // يجهّز خدمة قاعدة البيانات المستخدمة في عمليات البلاغات.
    private init(
        firestoreService: FirestoreService = .shared
    ) {
        self.firestoreService = firestoreService
    }
    
    
    // يجيب مستندات البلاغات ويحوّلها إلى نماذج، ويتجاوز المستندات الناقصة.
    func fetchEmergencyAlerts() async throws -> [EmergencyAlertModel] {
        
        let documents = try await firestoreService.fetchEmergencyAlerts(
            from: FirestoreCollections.emergencyAlert
        )
        
        return documents.compactMap { document in
            
            let data = document.data()
            
            guard
                let alertID = data["AlertID"] as? Int,
                let description = data["Description"] as? String,
                let timestamp = data["Time"] as? Timestamp,
                let pilgrimUsername = data["PI_Username"] as? String
            else {
                return nil
            }
            
            return EmergencyAlertModel(
                alertID: alertID,
                description: description,
                time: timestamp.dateValue(),
                paramedicUsername: data["PA_Username"] as? String,
                pilgrimUsername: pilgrimUsername,
                companionUsername: data["CompanionUserName"] as? String
            )
        }
    }
    
        // يبحث باسم مستخدم الحاج ويرجع موقعه، أو nil إذا لم تتوفر بيانات الموقع المطلوبة.
        func fetchLocation(
        for pilgrimUsername: String
    ) async throws -> LocationModel? {
        
        let documents = try await firestoreService.fetchDocuments(
            from: FirestoreCollections.location
        )
        
        guard let document = documents.first(
            where: {
                $0.data()["PI_Username"] as? String == pilgrimUsername
            }
        ) else {
            return nil
        }
        
        let data = document.data()
        
        guard
            let latitude = data["Latitude"] as? Double,
            let longitude = data["Longitude"] as? Double,
            let timestamp = data["TimeStamp"] as? Timestamp
        else {
            return nil
        }
        
        return LocationModel(
            latitude: latitude,
            longitude: longitude,
            timeStamp: timestamp.dateValue(),
            pilgrimUsername: pilgrimUsername
        )
    }
    
    
    // يجيب بيانات الحاج حسب اسم المستخدم ويتأكد من وجود الحقول الأساسية.
    func fetchPilgrim(
        username: String
    ) async throws -> PilgrimModel? {
        
        let documents = try await firestoreService.fetchDocuments(
            from: FirestoreCollections.pilgrim
        )
        
        guard let document = documents.first(
            where: {
                $0.data()["PI_Username"] as? String == username
            }
        ) else {
            return nil
        }
        
        let data = document.data()
        
        guard
            let email = data["Email"] as? String,
            let nationality = data["Nationality"] as? String,
            let language = data["Language"] as? String,
            let age = data["Age"] as? Int,
            let firstName = data["Fname"] as? String,
            let lastName = data["Lname"] as? String,
            let phoneNumber = data["PhoneNumber"] as? String
        else {
            return nil
        }
        
        return PilgrimModel(
            username: username,
            email: email,
            nationality: nationality,
            language: language,
            age: age,
            firstName: firstName,
            lastName: lastName,
            phoneNumber: phoneNumber,
            heartRate: data["Heart_rate"] as? Double
        )
    }
    
    
    // يجيب السجل الطبي المرتبط باسم مستخدم الحاج.
    func fetchMedicalRecord(
        for pilgrimUsername: String
    ) async throws -> MedicalRecordModel? {
        
        let documents = try await firestoreService.fetchDocuments(
            from: FirestoreCollections.medicalRecord
        )
        
        guard let document = documents.first(
            where: {
                $0.data()["PI_Username"] as? String == pilgrimUsername
            }
        ) else {
            return nil
        }
        
        let data = document.data()
        
        guard
            let gender = data["Gender"] as? String,
            let medications = data["Medications"] as? String,
            let bloodType = data["BloodType"] as? String,
            let allergies = data["Allergies"] as? String,
            let chronicDiseases = data["ChronicDiseases"] as? String
        else {
            return nil
        }
        
        return MedicalRecordModel(
            gender: gender,
            medications: medications,
            bloodType: bloodType,
            allergies: allergies,
            chronicDiseases: chronicDiseases,
            otherInfo: data["OtherInfo"] as? String,
            pilgrimUsername: pilgrimUsername
        )
    }
    
        // يبحث عن البلاغ برقمه ويحدّث اسم المسعف المسؤول عنه.
        func acceptEmergency(
        alertID: Int,
        paramedicUsername: String
    ) async throws {
        
        let documents = try await firestoreService.fetchDocuments(
            from: FirestoreCollections.emergencyAlert
        )
        
        guard let document = documents.first(
            where: {
                $0.data()["AlertID"] as? Int == alertID
            }
        ) else {
            throw NSError(
                domain: "Emergency",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Emergency alert was not found."
                ]
            )
        }
        
        let documentReference = Firestore.firestore()
            .collection(FirestoreCollections.emergencyAlert)
            .document(document.documentID)
        
        try await withCheckedThrowingContinuation {
            (continuation: CheckedContinuation<Void, Error>) in
            
            Firestore.firestore().runTransaction({
                transaction,
                errorPointer -> Any? in
                
                let snapshot: DocumentSnapshot
                
                do {
                    snapshot = try transaction.getDocument(
                        documentReference
                    )
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
                
                let data = snapshot.data() ?? [:]
                
                if let existingParamedic =
                    data["PA_Username"] as? String,
                   !existingParamedic.isEmpty,
                   existingParamedic != paramedicUsername {
                    
                    errorPointer?.pointee = NSError(
                        domain: "Emergency",
                        code: 409,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "This emergency has already been accepted by another paramedic."
                        ]
                    )
                    
                    return nil
                }
                
                transaction.updateData(
                    [
                        "PA_Username": paramedicUsername
                    ],
                    forDocument: documentReference
                )
                
                return nil
                
            }) { _, error in
                
                if let error = error {
                    continuation.resume(
                        throwing: error
                    )
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    // يضيف تفاصيل الحالة والمساعدة المقدمة إلى سجل المسعف، مع اسم المرافق اذا وجد.
    func addCaseHistory(
        paramedicUsername: String,
        alertID: Int,
        pilgrimUsername: String,
        companionUsername: String?,
        caseType: CaseHistoryType,
        assistanceProvided: String
    ) async throws {
        
        let documents = try await firestoreService.fetchDocuments(
            from: FirestoreCollections.paramedic
        )
        
        guard let document = documents.first(
            where: {
                $0.data()["PA_Username"] as? String == paramedicUsername
            }
        ) else {
            return
        }
        
        var caseHistoryEntry: [String: Any] = [
            "AlertID": alertID,
            "PI_Username": pilgrimUsername,
            "CaseType": caseType.rawValue,
            "AssistanceProvided": assistanceProvided,
            "CompletedAt": Timestamp(date: Date())
        ]
        
        if let companionUsername {
            caseHistoryEntry["CompanionUserName"] = companionUsername
        }
        
        try await Firestore.firestore()
            .collection(FirestoreCollections.paramedic)
            .document(document.documentID)
            .updateData([
                "PA_CaseHistory": FieldValue.arrayUnion([
                    caseHistoryEntry
                ])
            ])
    }
    
   
    // يقرأ سجل المسعف ويحوّله إلى حالات مرتبة من الأحدث إلى الأقدم.
    func fetchCaseHistory(
        paramedicUsername: String
    ) async throws -> [CaseHistoryModel] {
        
        let documents = try await firestoreService.fetchDocuments(
            from: FirestoreCollections.paramedic
        )
        
        guard let document = documents.first(
            where: {
                $0.data()["PA_Username"] as? String == paramedicUsername
            }
        ) else {
            return []
        }
        
        let data = document.data()
        
        guard
            let history = data["PA_CaseHistory"] as? [[String: Any]]
        else {
            return []
        }
        
        let cases = history.compactMap {
            item -> CaseHistoryModel? in
            
            guard
                let alertID = item["AlertID"] as? Int,
                let pilgrimUsername = item["PI_Username"] as? String,
                let assistanceProvided =
                    item["AssistanceProvided"] as? String,
                let completedAt =
                    item["CompletedAt"] as? Timestamp
            else {
                return nil
            }
            
            let caseTypeRawValue =
                item["CaseType"] as? String
                ?? CaseHistoryType.patient.rawValue
            
            let caseType =
                CaseHistoryType(
                    rawValue: caseTypeRawValue
                ) ?? .patient
            
            return CaseHistoryModel(
                id: UUID().uuidString,
                alertID: alertID,
                paramedicUsername: paramedicUsername,
                pilgrimUsername: pilgrimUsername,
                companionUsername:
                    item["CompanionUserName"] as? String,
                caseType: caseType,
                assistanceProvided: assistanceProvided,
                completedAt: completedAt.dateValue()
            )
        }
        
        return cases.sorted {
            $0.completedAt > $1.completedAt
        }
    }
    
    
    // يحذف مستند البلاغ المطابق لرقم البلاغ المحدد.
    func deleteEmergencyAlert(
        alertID: Int
    ) async throws {
        
        let documents = try await firestoreService.fetchDocuments(
            from: FirestoreCollections.emergencyAlert
        )
        
        guard let document = documents.first(
            where: {
                $0.data()["AlertID"] as? Int == alertID
            }
        ) else {
            return
        }
        
        try await firestoreService.deleteDocument(
            collectionName: FirestoreCollections.emergencyAlert,
            documentID: document.documentID
        )
    }
    
        // يجمع بيانات كل بلاغ مع الموقع وبيانات الحاج أو المرافق لتجهيز نقاط الخريطة.
        func fetchActiveEmergencies(
        paramedicUsername: String
    ) async throws -> [EmergencyLocation] {
        
        let allAlerts = try await fetchEmergencyAlerts()
        
        let alerts = allAlerts.filter { alert in
            
            guard
                let assignedParamedic = alert.paramedicUsername,
                !assignedParamedic.isEmpty
            else {
                return true
            }
            
            return assignedParamedic == paramedicUsername
        }
        
        var emergencyLocations: [EmergencyLocation] = []
        
        for alert in alerts {
            
            guard
                let location = try await fetchLocation(
                    for: alert.pilgrimUsername
                )
            else {
                continue
            }
            
          
            if let companionUsername = alert.companionUsername {
                
                guard
                    let companion = try await fetchPilgrim(
                        username: companionUsername
                    )
                else {
                    continue
                }
                
                let companionReport = CompanionReportModel(
                    id: String(alert.alertID),
                    companionUsername: companionUsername,
                    pilgrimUsername: alert.pilgrimUsername,
                    situationDescription: alert.description
                )
                
                let emergencyLocation =
                    ParamedicDataMapper
                    .makeCompanionEmergencyLocation(
                        alert: alert,
                        location: location,
                        companionReport: companionReport,
                        reporterName: companion.fullName,
                        reporterPhoneNumber:
                            companion.phoneNumber
                    )
                
                emergencyLocations.append(
                    emergencyLocation
                )
                
                continue
            }
            
           
            guard
                let pilgrim = try await fetchPilgrim(
                    username: alert.pilgrimUsername
                ),
                let medicalRecord =
                    try await fetchMedicalRecord(
                        for: alert.pilgrimUsername
                    )
            else {
                continue
            }
            
            let emergencyLocation =
                ParamedicDataMapper.makeEmergencyLocation(
                    alert: alert,
                    location: location,
                    pilgrim: pilgrim,
                    medicalRecord: medicalRecord
                )
            
            emergencyLocations.append(
                emergencyLocation
            )
        }
        
        return emergencyLocations
    }
}
