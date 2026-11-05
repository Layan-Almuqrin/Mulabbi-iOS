import Foundation
import FirebaseFirestore

/// مسؤول عن حفظ وإدارة بيانات المرافقين في فايربيس.
final class CompanionFirebase {
    private let database = Firestore.firestore()
    /// يبحث عن مستخدم مسجل باستخدام رقم جواله لإضافته كمرافق.
    func findPilgrim(
        by phoneNumber: String,
        completion: @escaping (Result<Companion?, Error>) -> Void
    ) {
        database.collection("pilgrims")
            .whereField("phoneNumber", isEqualTo: phoneNumber)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard
                    let document = snapshot?.documents.first,
                    let username = document["username"] as? String,
                    let firstName = document["firstName"] as? String,
                    let lastName = document["lastName"] as? String,
                    let phoneNumber = document["phoneNumber"] as? String
                else {
                    completion(.success(nil))
                    return
                }

                let companion = Companion(
                    name: "\(firstName) \(lastName)",
                    username: username,
                    phoneNumber: phoneNumber
                )

                completion(.success(companion))
            }
    }
    
    /// يبحث عن بيانات صاحب طلب الإضافة باستخدام اسم المستخدم
    func findPilgrim(
        byUsername username: String,
        completion: @escaping (Result<Companion?, Error>) -> Void
    ) {
        database.collection("pilgrims")
            .whereField("username", isEqualTo: username)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard
                    let document = snapshot?.documents.first,
                    let firstName = document["firstName"] as? String,
                    let lastName = document["lastName"] as? String,
                    let phoneNumber = document["phoneNumber"] as? String
                else {
                    completion(.success(nil))
                    return
                }

                let pilgrim = Companion(
                    name: "\(firstName) \(lastName)",
                    username: username,
                    phoneNumber: phoneNumber
                )

                completion(.success(pilgrim))
            }
    }
    /// يجلب بيانات صاحب الطلب ثم يحفظ طلب اضافة المرافق للطرفين بانتظار القبول
    func sendCompanionRequest(
        pilgrimUsername: String,
        companion: Companion,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        findPilgrim(byUsername: pilgrimUsername) { result in
            switch result {
            case .success(let pilgrim):
                guard let pilgrim else {
                    return
                }

                let requestData: [String: Any] = [
                    "pilgrimUsername": pilgrim.username,
                    "pilgrimName": pilgrim.name,
                    "pilgrimPhoneNumber": pilgrim.phoneNumber,
                    "companionUsername": companion.username,
                    "companionName": companion.name,
                    "companionPhoneNumber": companion.phoneNumber,
                    "status": "pending",
                    "isAlertEnabled": true
                ]

                self.database.collection("companion_connections")
                    .addDocument(data: requestData) { error in
                        if let error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    /// يحضر طلبات اضافة المرافق المرسلة للمستخدم والتي ما زالت بانتظار موافقته او رفضه
    func fetchIncomingRequests(
        for companionUsername: String,
        completion: @escaping (Result<[Companion], Error>) -> Void
    ) {
        database.collection("companion_connections")
            .whereField("companionUsername", isEqualTo: companionUsername)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let requests = snapshot?.documents.compactMap { document -> Companion? in
                    guard
                        let status = document["status"] as? String,
                        status == "pending",
                        let pilgrimName = document["pilgrimName"] as? String,
                        let pilgrimUsername = document["pilgrimUsername"] as? String,
                        let pilgrimPhoneNumber = document["pilgrimPhoneNumber"] as? String
                    else {
                        return nil
                    }

                    return Companion(
                        name: pilgrimName,
                        username: pilgrimUsername,
                        phoneNumber: pilgrimPhoneNumber,
                        isAlertEnabled: document["isAlertEnabled"] as? Bool ?? true,
                        connectionId: document.documentID
                    )
                } ?? []

                completion(.success(requests))
            }
    }
    /// يحدث حالة طلب المرافق الى مقبول او مرفوض
    func updateRequestStatus(
        connectionId: String,
        status: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        database.collection("companion_connections")
            .document(connectionId)
            .updateData(["status": status]) { error in
                if let error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }
    
    /// يحفظ حالة تفعيل أو تعطيل تنبيهات المرافق في فايربيس
    func updateAlertStatus(
        connectionId: String,
        isAlertEnabled: Bool
    ) {
        database.collection("companion_connections")
            .document(connectionId)
            .updateData([
                "isAlertEnabled": isAlertEnabled
         ])
    }
    /// يحضر المرافقين الذين قبلت طلباتهم للمستخدم من الداتابيس
    func fetchAcceptedCompanions(
        for username: String,
        completion: @escaping (Result<[Companion], Error>) -> Void
    ) {
        database.collection("companion_connections")
            .whereField("companionUsername", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let companions = snapshot?.documents.compactMap { document -> Companion? in
                    guard
                        let status = document["status"] as? String,
                        status == "accepted",
                        let pilgrimName = document["pilgrimName"] as? String,
                        let pilgrimUsername = document["pilgrimUsername"] as? String,
                        let pilgrimPhoneNumber = document["pilgrimPhoneNumber"] as? String
                    else {
                        return nil
                    }

                    return Companion(
                        name: pilgrimName,
                        username: pilgrimUsername,
                        phoneNumber: pilgrimPhoneNumber,
                        isAlertEnabled: document["isAlertEnabled"] as? Bool ?? true,
                        connectionId: document.documentID
                    )
                } ?? []

                completion(.success(companions))
            }
    }
    
    /// يجلب المرافقين المقبولين الذين تنبيهاتهم مفعله لارسال تنبيه الطوارئ لهم
    func fetchEnabledCompanions(
        for pilgrimUsername: String,
        completion: @escaping (Result<[Companion], Error>) -> Void
    ) {
        database.collection("companion_connections")
            .whereField("pilgrimUsername", isEqualTo: pilgrimUsername)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                let companions = snapshot?.documents.compactMap { document -> Companion? in
                    guard
                        let status = document["status"] as? String,
                        status == "accepted",
                        let isAlertEnabled = document["isAlertEnabled"] as? Bool,
                        isAlertEnabled,
                        let companionName = document["companionName"] as? String,
                        let companionUsername = document["companionUsername"] as? String,
                        let companionPhoneNumber = document["companionPhoneNumber"] as? String
                    else {
                        return nil
                    }

                    return Companion(
                        name: companionName,
                        username: companionUsername,
                        phoneNumber: companionPhoneNumber,
                        isAlertEnabled: true,
                        connectionId: document.documentID
                    )
                } ?? []

                completion(.success(companions))
            }
    }
}

