import Foundation
import FirebaseFirestore

/// Matches the schema written by the existing pilgrim code. No data migration.
enum ParamedicEmergencySchema {
    static let alerts = "emergency_alerts"
    static let locations = "locations"
    static let users = "users"

    static func decodeAlert(id: String, data: [String: Any]) -> EmergencyAlertModel? {
        guard let pilgrim = data["PIUsername"] as? String, !pilgrim.isEmpty,
              let time = data["time"] as? Timestamp,
              let description = data["description"] as? String else { return nil }
        return EmergencyAlertModel(
            alertID: id, description: description, time: time.dateValue(),
            paramedicUsername: data["PAUsername"] as? String,
            pilgrimUsername: pilgrim,
            companionUsername: data["companionUsername"] as? String,
            isRequestForOther: data["isRequestForOther"] as? Bool ?? false,
            status: data["status"] as? String ?? "pending"
        )
    }

    static func isVisible(_ alert: EmergencyAlertModel, to username: String) -> Bool {
        guard ["pending", "accepted"].contains(alert.status) else { return false }
        let owner = alert.paramedicUsername ?? ""
        return owner.isEmpty || sameUsername(owner, username)
    }

    static func sameUsername(_ lhs: String, _ rhs: String) -> Bool {
        lhs.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            == rhs.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func canAccept(_ data: [String: Any], username: String) -> Bool {
        let status = data["status"] as? String ?? "pending"
        guard ["pending", "accepted"].contains(status) else { return false }
        let owner = data["PAUsername"] as? String ?? ""
        return owner.isEmpty || sameUsername(owner, username)
    }

    static func canComplete(_ data: [String: Any], username: String) -> Bool {
        data["status"] as? String == "accepted"
            && sameUsername(data["PAUsername"] as? String ?? "", username)
    }

    static func location(_ data: [String: Any]) -> LocationModel? {
        guard let latitude = data["latitude"] as? Double,
              let longitude = data["longitude"] as? Double,
              (-90...90).contains(latitude), (-180...180).contains(longitude),
              let username = data["PIUsername"] as? String,
              let timestamp = data["timestamp"] as? Timestamp else { return nil }
        return LocationModel(latitude: latitude, longitude: longitude,
                             timeStamp: timestamp.dateValue(), pilgrimUsername: username)
    }

    static func pilgrim(_ data: [String: Any]) -> PilgrimModel? {
        guard data["role"] as? String == "pilgrim",
              let username = data["username"] as? String,
              let first = data["firstName"] as? String,
              let last = data["lastName"] as? String else { return nil }
        return PilgrimModel(
            username: username, email: data["email"] as? String ?? "",
            nationality: data["nationality"] as? String ?? "",
            language: (data["languages"] as? [String] ?? []).joined(separator: ", "),
            age: (data["age"] as? NSNumber)?.intValue ?? 0,
            firstName: first, lastName: last, phoneNumber: data["phoneNumber"] as? String ?? "",
            heartRate: data["heartRate"] as? Double
        )
    }

    static func medical(_ data: [String: Any]) -> MedicalRecordModel? {
        guard let username = data["username"] as? String else { return nil }
        let record = data["medicalRecord"] as? [String: Any] ?? [:]
        return MedicalRecordModel(
            gender: record["gender"] as? String ?? "",
            medications: record["medications"] as? String ?? "",
            bloodType: record["bloodType"] as? String ?? "",
            allergies: record["allergies"] as? String ?? "",
            chronicDiseases: record["chronicDiseases"] as? String ?? "",
            otherInfo: record["otherInfo"] as? String,
            pilgrimUsername: username
        )
    }
}
