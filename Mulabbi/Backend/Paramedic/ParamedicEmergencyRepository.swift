import Foundation
import FirebaseAuth
import FirebaseFirestore
import MapKit

final class ParamedicEmergencyRepository {
    static let shared = ParamedicEmergencyRepository()
    private let database = Firestore.firestore()
    private init() {}

    func fetchEmergencyAlerts() async throws -> [EmergencyAlertModel] {
        let snapshot = try await database.collection(ParamedicEmergencySchema.alerts).getDocuments()
        return snapshot.documents.compactMap {
            ParamedicEmergencySchema.decodeAlert(id: $0.documentID, data: $0.data())
        }
    }

    /// The alert ID is essential: one pilgrim can have several location records.
    func fetchLocation(alertID: String) async throws -> LocationModel? {
        let snapshot = try await database.collection(ParamedicEmergencySchema.locations)
            .whereField("alertId", isEqualTo: alertID).getDocuments()
        return snapshot.documents.compactMap { ParamedicEmergencySchema.location($0.data()) }
            .max { $0.timeStamp < $1.timeStamp }
    }

    private func userData(username: String) async throws -> [String: Any]? {
        // Use the same username registry as login, then fall back to the exact
        // username query used by the companion code (for existing profiles).
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let identity = try await database.collection("usernames").document(key).getDocument()
        if let uid = identity.data()?["uid"] as? String {
            let profile = try await database.collection(ParamedicEmergencySchema.users).document(uid).getDocument()
            if let data = profile.data(),
               ParamedicEmergencySchema.sameUsername(data["username"] as? String ?? "", username) {
                return data
            }
        }
        let profiles = try await database.collection(ParamedicEmergencySchema.users)
            .whereField("username", isEqualTo: username).limit(to: 1).getDocuments()
        return profiles.documents.first?.data()
    }

    func fetchPilgrim(username: String) async throws -> PilgrimModel? {
        guard let data = try await userData(username: username) else { return nil }
        return ParamedicEmergencySchema.pilgrim(data)
    }

    func fetchMedicalRecord(for username: String) async throws -> MedicalRecordModel? {
        guard let data = try await userData(username: username),
              data["role"] as? String == "pilgrim" else { return nil }
        return ParamedicEmergencySchema.medical(data)
    }

    private func paramedicProfile(username: String) async throws -> (DocumentReference, String) {
        guard let uid = Auth.auth().currentUser?.uid else { throw failure("Please sign in again.") }
        let reference = database.collection(ParamedicEmergencySchema.users).document(uid)
        let snapshot = try await reference.getDocument()
        guard let data = snapshot.data(), data["role"] as? String == "paramedic",
              let canonical = data["username"] as? String,
              ParamedicEmergencySchema.sameUsername(canonical, username) else {
            throw failure("The signed-in paramedic does not match this account.")
        }
        return (reference, canonical)
    }

    func acceptEmergency(alertID: String, paramedicUsername: String) async throws {
        let (_, username) = try await paramedicProfile(username: paramedicUsername)
        let alert = database.collection(ParamedicEmergencySchema.alerts).document(alertID)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.runTransaction({ transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(alert)
                    guard let data = snapshot.data() else { throw self.failure("This request no longer exists.") }
                    guard ParamedicEmergencySchema.canAccept(data, username: username) else {
                        throw self.failure("This request has already been accepted or closed.")
                    }
                    transaction.updateData([
                        "PAUsername": username, "status": "accepted",
                        "acceptedAt": FieldValue.serverTimestamp()
                    ], forDocument: alert)
                } catch { errorPointer?.pointee = error as NSError }
                return nil
            }) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    /// History and status are committed atomically. Keep the original document
    /// so the pilgrim's existing status listener can observe completion.
    func completeEmergency(alertID: String, paramedicUsername: String, description: String) async throws {
        let (paramedic, username) = try await paramedicProfile(username: paramedicUsername)
        let alert = database.collection(ParamedicEmergencySchema.alerts).document(alertID)
        let alertSnapshot = try await alert.getDocument()
        guard let data = alertSnapshot.data(),
              let pilgrimUsername = data["PIUsername"] as? String,
              let profile = try await userData(username: pilgrimUsername),
              let location = try await fetchLocation(alertID: alertID) else {
            throw failure("The request or patient details are unavailable. Please try again.")
        }
        var history: [String: Any] = [
            "alertId": alertID, "PIUsername": pilgrimUsername, "PAUsername": username,
            "description": description, "completedAt": FieldValue.serverTimestamp(),
            "caseType": "patient", "pilgrimProfile": profile,
            "latitude": location.latitude, "longitude": location.longitude
        ]
        if data["isRequestForOther"] as? Bool == true {
            history["caseType"] = "companion"
            history["isRequestForOther"] = true
            history["companionUsername"] = pilgrimUsername
            history["companionProfile"] = profile
        } else if let companion = data["companionUsername"] as? String {
            history["companionUsername"] = companion
            history["caseType"] = "companion"
            if let companionProfile = try await userData(username: companion) {
                history["companionProfile"] = companionProfile
            }
        }
        let historyData = history
        let historyReference = paramedic.collection("caseHistory").document(alertID)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            database.runTransaction({ transaction, errorPointer -> Any? in
                do {
                    let current = try transaction.getDocument(alert)
                    let previousHistory = try transaction.getDocument(historyReference)
                    guard let latest = current.data() else { throw self.failure("This request no longer exists.") }
                    // A retry after a successful commit must not duplicate history.
                    if latest["status"] as? String == "completed",
                       ParamedicEmergencySchema.sameUsername(latest["PAUsername"] as? String ?? "", username),
                       previousHistory.exists { return nil }
                    guard ParamedicEmergencySchema.canComplete(latest, username: username),
                          latest["PIUsername"] as? String == pilgrimUsername else {
                        throw self.failure("Only the paramedic assigned to this request can complete it.")
                    }
                    transaction.setData(historyData, forDocument: historyReference)
                    transaction.updateData([
                        "status": "completed", "completedAt": FieldValue.serverTimestamp()
                    ], forDocument: alert)
                } catch { errorPointer?.pointee = error as NSError }
                return nil
            }) { _, error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }

    func fetchActiveEmergencies(paramedicUsername: String) async throws -> [EmergencyLocation] {
        guard !paramedicUsername.isEmpty else { return [] }
        let alerts = try await fetchEmergencyAlerts().filter {
            ParamedicEmergencySchema.isVisible($0, to: paramedicUsername)
        }
        var locations: [EmergencyLocation] = []
        for alert in alerts {
            try Task.checkCancellation()
            guard let location = try await fetchLocation(alertID: alert.alertID),
                  ParamedicEmergencySchema.sameUsername(location.pilgrimUsername, alert.pilgrimUsername) else { continue }
            if alert.isRequestForOther,
               let reporter = try await fetchPilgrim(username: alert.pilgrimUsername) {
                locations.append(ParamedicDataMapper.makeCompanionEmergencyLocation(
                    alert: alert, location: location,
                    companionReport: CompanionReportModel(
                        id: alert.alertID,
                        companionUsername: alert.pilgrimUsername,
                        pilgrimUsername: alert.pilgrimUsername,
                        situationDescription: alert.description,
                        isRequestForOther: true
                    ),
                    reporterName: reporter.fullName,
                    reporterPhoneNumber: reporter.phoneNumber
                ))
            } else if let companionUsername = alert.companionUsername,
               let companion = try await fetchPilgrim(username: companionUsername) {
                locations.append(ParamedicDataMapper.makeCompanionEmergencyLocation(
                    alert: alert, location: location,
                    companionReport: CompanionReportModel(
                        id: alert.alertID, companionUsername: companionUsername,
                        pilgrimUsername: alert.pilgrimUsername, situationDescription: alert.description),
                    reporterName: companion.fullName, reporterPhoneNumber: companion.phoneNumber
                ))
            } else if let pilgrim = try await fetchPilgrim(username: alert.pilgrimUsername),
                      let medical = try await fetchMedicalRecord(for: alert.pilgrimUsername) {
                locations.append(ParamedicDataMapper.makeEmergencyLocation(
                    alert: alert, location: location, pilgrim: pilgrim, medicalRecord: medical))
            }
        }
        return locations
    }

    func fetchCompletedEmergencies(paramedicUsername: String) async throws -> [CompletedEmergency] {
        let (paramedic, _) = try await paramedicProfile(username: paramedicUsername)
        let snapshot = try await paramedic.collection("caseHistory").getDocuments()
        var cases: [CompletedEmergency] = snapshot.documents.compactMap { document in
            let data = document.data()
            guard let profile = data["pilgrimProfile"] as? [String: Any],
                  let pilgrim = ParamedicEmergencySchema.pilgrim(profile),
                  let medical = ParamedicEmergencySchema.medical(profile),
                  let latitude = data["latitude"] as? Double,
                  let longitude = data["longitude"] as? Double,
                  let completedAt = data["completedAt"] as? Timestamp else { return nil }
            let type: EmergencyType
            let caseType = (data["caseType"] as? String ?? "").lowercased()
            let isRequestForOther = data["isRequestForOther"] as? Bool == true
            let companionUsername = data["companionUsername"] as? String
            if isRequestForOther || caseType == "report" || caseType == "companion"
                || companionUsername != nil || data["companionProfile"] != nil {
                // Never turn a report into a patient when its reporter profile is missing.
                let reporterData = data["companionProfile"] as? [String: Any]
                    ?? ((isRequestForOther || caseType == "report") ? profile : [:])
                let reporter = ParamedicEmergencySchema.pilgrim(reporterData)
                type = .companion(CompanionEmergencyReport(
                    id: document.documentID, reporterName: reporter?.fullName ?? "",
                    reporterUsername: companionUsername ?? reporter?.username ?? "",
                    reporterPhoneNumber: reporter?.phoneNumber ?? "",
                    situationDescription: "", isRequestForOther: isRequestForOther || caseType == "report"))
            } else {
                type = .patient(ParamedicDataMapper.makeEmergencyPatient(pilgrim: pilgrim, medicalRecord: medical))
            }
            return CompletedEmergency(
                emergencyID: UUID(), type: type,
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                description: data["description"] as? String ?? data["AssistanceProvided"] as? String ?? "", completedAt: completedAt.dateValue())
        }
        // Read-only compatibility with existing history; no migration or deletion.
        if let legacy = try? await database.collection("PARAMEDIC")
            .whereField("PA_Username", isEqualTo: paramedicUsername).getDocuments() {
            let newIDs = Set(snapshot.documents.map(\.documentID))
            for document in legacy.documents {
                for data in document.data()["PA_CaseHistory"] as? [[String: Any]] ?? [] {
                    guard let rawID = data["AlertID"],
                          !newIDs.contains(String(describing: rawID)),
                          let username = data["PI_Username"] as? String,
                          let completedAt = data["CompletedAt"] as? Timestamp,
                          let pilgrim = try await fetchLegacyPilgrim(username: username),
                          let medical = try await fetchLegacyMedical(username: username),
                          let location = try await fetchLegacyLocation(username: username) else { continue }
                    let type: EmergencyType
                    if let companionName = data["CompanionUserName"] as? String {
                        let companion = try await fetchLegacyPilgrim(username: companionName)
                        type = .companion(CompanionEmergencyReport(
                            id: String(describing: rawID), reporterName: companion?.fullName ?? "",
                            reporterUsername: companionName, reporterPhoneNumber: companion?.phoneNumber ?? "",
                            situationDescription: ""))
                    } else {
                        type = .patient(ParamedicDataMapper.makeEmergencyPatient(pilgrim: pilgrim, medicalRecord: medical))
                    }
                    cases.append(CompletedEmergency(
                        emergencyID: UUID(), type: type,
                        coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                        description: data["AssistanceProvided"] as? String ?? "", completedAt: completedAt.dateValue()))
                }
            }
        }
        return cases.sorted { $0.completedAt > $1.completedAt }
    }

    private func legacyData(collection: String, username: String) async throws -> [String: Any]? {
        let snapshot = try await database.collection(collection)
            .whereField("PI_Username", isEqualTo: username).limit(to: 1).getDocuments()
        return snapshot.documents.first?.data()
    }
    private func fetchLegacyPilgrim(username: String) async throws -> PilgrimModel? {
        guard var data = try await legacyData(collection: "PILGRIM", username: username) else { return nil }
        data["role"] = "pilgrim"; data["username"] = username
        for (old, new) in [("Fname", "firstName"), ("Lname", "lastName"), ("Email", "email"),
                           ("Age", "age"), ("Nationality", "nationality"), ("PhoneNumber", "phoneNumber")] {
            data[new] = data[old]
        }
        data["languages"] = [data["Language"] as? String ?? ""]
        return ParamedicEmergencySchema.pilgrim(data)
    }
    private func fetchLegacyMedical(username: String) async throws -> MedicalRecordModel? {
        guard let old = try await legacyData(collection: "MEDICAL_RECORD", username: username) else { return nil }
        var record: [String: Any] = [:]
        for (key, value) in [("Gender", "gender"), ("Medications", "medications"), ("BloodType", "bloodType"),
                             ("Allergies", "allergies"), ("ChronicDiseases", "chronicDiseases"), ("OtherInfo", "otherInfo")] {
            record[value] = old[key]
        }
        return ParamedicEmergencySchema.medical(["username": username, "medicalRecord": record])
    }
    private func fetchLegacyLocation(username: String) async throws -> LocationModel? {
        guard let data = try await legacyData(collection: "LOCATION", username: username),
              let lat = data["Latitude"] as? Double, let lon = data["Longitude"] as? Double,
              let time = data["TimeStamp"] as? Timestamp else { return nil }
        return LocationModel(latitude: lat, longitude: lon, timeStamp: time.dateValue(), pilgrimUsername: username)
    }

    private func failure(_ message: String) -> NSError {
        NSError(domain: "ParamedicEmergency", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
