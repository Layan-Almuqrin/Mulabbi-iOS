import SwiftUI
import MapKit
import Combine


struct CompletedEmergency: Identifiable {
    
    let id = UUID()
    
    let emergencyID: UUID
    
    let type: EmergencyType
    
    let coordinate: CLLocationCoordinate2D
    
    let description: String
    
    let completedAt: Date
}


final class EmergencyStore: ObservableObject {
    
    
    private let repository = ParamedicEmergencyRepository.shared
    
    let currentParamedicUsername: String

    // Empty identity supports previews and legacy standalone screens only.
    // يحفظ اسم المسعف الحالي لاستخدامه عند قبول البلاغات وتسجيل الحالات.
    init(paramedicUsername: String = "") {
        self.currentParamedicUsername = paramedicUsername.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    @Published var emergencyLocations: [EmergencyLocation] = []
    
    
    @Published var activeEmergencyID: UUID? = nil
    
    
    @Published var completedEmergencies: [CompletedEmergency] = []
    
    
    @Published var isLoadingEmergencies = false
    
    
    @Published var isLoadingCaseHistory = false
    
    
   
    
    // يجيب البلاغات من قاعدة البيانات ويحدّث مواقعها  في الواجهة.
    func loadEmergencies() async {
        
        await MainActor.run {
            isLoadingEmergencies = true
        }
        
        do {
            
            let firestoreEmergencies =
                try await repository.fetchActiveEmergencies(
                    paramedicUsername: currentParamedicUsername
                )
            await MainActor.run {
                
                emergencyLocations = firestoreEmergencies
                
                isLoadingEmergencies = false
            }
            
        } catch {
            
            print(
                "Failed to load emergencies from Firestore: \(error.localizedDescription)"
            )
            
            await MainActor.run {
                isLoadingEmergencies = false
            }
        }
    }
    
    
    
    
    // يجيب سجل المسعف ويجهّز بيانات الحالات السابقة لعرضها، سواء كانت لحاج أو بلاغ مرافق.
    func loadCaseHistory() async {
        guard !currentParamedicUsername.isEmpty else { return }

        
        await MainActor.run {
            isLoadingCaseHistory = true
        }
        
        do {
            
            let history = try await repository.fetchCaseHistory(
                paramedicUsername: currentParamedicUsername
            )
            
            var loadedCases: [CompletedEmergency] = []
            
            
            for historyItem in history {
                
                
                // Companion Case
                
                if historyItem.caseType == .companion,
                   let companionUsername = historyItem.companionUsername {
                    
                    guard
                        let companion = try await repository.fetchPilgrim(
                            username: companionUsername
                        ),
                        let location = try await repository.fetchLocation(
                            for: historyItem.pilgrimUsername
                        )
                    else {
                        continue
                    }
                    
                    
                    let report = CompanionEmergencyReport(
                        id: String(historyItem.alertID),
                        reporterName: companion.fullName,
                        reporterUsername: companion.username,
                        reporterPhoneNumber: companion.phoneNumber,
                        situationDescription: ""
                    )
                    
                    
                    let completedEmergency = CompletedEmergency(
                        emergencyID: UUID(),
                        type: .companion(report),
                        coordinate: CLLocationCoordinate2D(
                            latitude: location.latitude,
                            longitude: location.longitude
                        ),
                        description: historyItem.assistanceProvided,
                        completedAt: historyItem.completedAt
                    )
                    
                    
                    loadedCases.append(
                        completedEmergency
                    )
                    
                    continue
                }
                
                
                // Patient Case
                
                guard
                    let pilgrim = try await repository.fetchPilgrim(
                        username: historyItem.pilgrimUsername
                    ),
                    let medicalRecord = try await repository.fetchMedicalRecord(
                        for: historyItem.pilgrimUsername
                    ),
                    let location = try await repository.fetchLocation(
                        for: historyItem.pilgrimUsername
                    )
                else {
                    continue
                }
                
                
                let patient =
                    ParamedicDataMapper.makeEmergencyPatient(
                        pilgrim: pilgrim,
                        medicalRecord: medicalRecord
                    )
                
                
                let completedEmergency = CompletedEmergency(
                    emergencyID: UUID(),
                    type: .patient(patient),
                    coordinate: CLLocationCoordinate2D(
                        latitude: location.latitude,
                        longitude: location.longitude
                    ),
                    description: historyItem.assistanceProvided,
                    completedAt: historyItem.completedAt
                )
                
                
                loadedCases.append(
                    completedEmergency
                )
            }
            
            
            await MainActor.run {
                
                completedEmergencies = loadedCases
                
                isLoadingCaseHistory = false
            }
            
        } catch {
            
            print(
                "Failed to load case history: \(error.localizedDescription)"
            )
            
            await MainActor.run {
                isLoadingCaseHistory = false
            }
        }
    }
    
    
    
    
    // يحدد البلاغ النشط محليًا ويربطه باسم المسعف في قاعدة البيانات.
    func acceptEmergency(
        emergencyID: UUID
    ) {
        guard !currentParamedicUsername.isEmpty else { return }

        
        guard let emergency = emergencyLocations.first(
            where: {
                $0.id == emergencyID
            }
        ) else {
            return
        }
        
        
        activeEmergencyID = emergencyID
        
        
        guard let alertID = emergency.alertID else {
            return
        }
        
        
        Task {
            
            do {
                
                try await repository.acceptEmergency(
                    alertID: alertID,
                    paramedicUsername: currentParamedicUsername
                )
                
                print(
                    "Emergency \(alertID) accepted successfully."
                )
                
            } catch {
                
                print(
                    "Failed to accept emergency: \(error.localizedDescription)"
                )
            }
        }
    }
    
    
   
    
    // يحفظ الحالة في سجل المسعف، ثم يحذف البلاغ ويحدّث قائمة البلاغات في الواجهة.
    func completeEmergency(
        emergencyID: UUID,
        description: String
    ) {
        guard !currentParamedicUsername.isEmpty else { return }

        
        guard let emergency = emergencyLocations.first(
            where: {
                $0.id == emergencyID
            }
        ) else {
            return
        }
        
        
        guard let alertID = emergency.alertID else {
            return
        }
        
        
        Task {
            
            do {
                
                let alerts = try await repository.fetchEmergencyAlerts()
                
                guard let originalAlert = alerts.first(
                    where: {
                        $0.alertID == alertID
                    }
                ) else {
                    return
                }
                
                
                let caseType: CaseHistoryType
                
                if originalAlert.companionUsername != nil {
                    caseType = .companion
                } else {
                    caseType = .patient
                }
                
                
                // 1. Save Case History
                
                try await repository.addCaseHistory(
                    paramedicUsername: currentParamedicUsername,
                    alertID: alertID,
                    pilgrimUsername: originalAlert.pilgrimUsername,
                    companionUsername: originalAlert.companionUsername,
                    caseType: caseType,
                    assistanceProvided: description
                )
                
                
                // 2. Delete completed alert
                
                try await repository.deleteEmergencyAlert(
                    alertID: alertID
                )
                
                
                // 3. Update app locally
                
                await MainActor.run {
                    
                    let completedEmergency = CompletedEmergency(
                        emergencyID: emergency.id,
                        type: emergency.type,
                        coordinate: emergency.coordinate,
                        description: description,
                        completedAt: Date()
                    )
                    
                    
                    completedEmergencies.append(
                        completedEmergency
                    )
                    
                    
                    emergencyLocations.removeAll {
                        $0.id == emergencyID
                    }
                    
                    
                    if activeEmergencyID == emergencyID {
                        activeEmergencyID = nil
                    }
                }
                
                
                print(
                    "Emergency \(alertID) completed successfully."
                )
                
            } catch {
                
                print(
                    "Failed to complete emergency: \(error.localizedDescription)"
                )
            }
        }
    }
}
