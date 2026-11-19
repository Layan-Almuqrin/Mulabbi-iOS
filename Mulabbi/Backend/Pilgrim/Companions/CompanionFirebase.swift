import Foundation
import FirebaseAuth
import FirebaseFirestore

enum CompanionRequestError: LocalizedError {
    case alreadyExists

    var errorDescription: String? {
        "This companion is already added or has a pending request."
    }
}

enum CompanionConnectionStatus: Equatable {
    case available
    case pending
    case accepted
}

/// مسؤول عن حفظ وإدارة بيانات المرافقين في فايربيس.
final class CompanionFirebase {
    private let database = Firestore.firestore()
    /// يبحث عن مستخدم مسجل باستخدام رقم جواله لإضافته كمرافق.
    func findPilgrim(
        by phoneNumber: String,
        completion: @escaping (Result<Companion?, Error>) -> Void
    ) {
        /// يحذف علامات التنسيق من الرقم قبل مقارنته بأرقام المستخدمين
        let enteredPhoneNumber = phoneNumber.filter(\.isNumber)

        database.collection("users")
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard
                    let document = snapshot?.documents.first(where: {
                        let savedPhoneNumber = ($0["phoneNumber"] as? String ?? "")
                            .filter(\.isNumber)
                        return savedPhoneNumber == enteredPhoneNumber
                            && ($0["role"] as? String) == "pilgrim"
                    }),
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
        database.collection("users")
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
    /// يرسل طلب اضافة مرافق ويحفظه في قاعدة البيانات بحالة انتظار
    func sendCompanionRequest(
        pilgrimUsername: String,
        companion: Companion,
        // يعيد نجاح العملية او الخطا عند فشلها
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // البحث عن بيانات المستخدم الذي يرسل طلب الإضافة
        findPilgrim(byUsername: pilgrimUsername) { result in
            switch result {
            case .success(let pilgrim):
                // التاكد من العثور على بيانات المستخدم
                guard let pilgrim else {
                    return
                }
                // تجهيز معلومات طلب الاضافة للطرفين
                let requestData: [String: Any] = [
                    "pilgrimUsername": pilgrim.username,
                    "pilgrimName": pilgrim.name,
                    "pilgrimPhoneNumber": pilgrim.phoneNumber,
                    "companionUsername": companion.username,
                    "companionName": companion.name,
                    "companionPhoneNumber": companion.phoneNumber,
                    // الطلب ينتظر موافقة المرافق
                    "status": "pending",
                    // تنبيهات الطوارئ مفعلة افتراضيا
                    "isAlertEnabled": true
                ]
            // التاكد من عدم وجود مرافق مضاف او طلب معلق مسبقا
                self.connectionStatus(
                    between: pilgrim.username,
                    and: companion.username
                ) { statusResult in
                    switch statusResult {
                    case .failure(let error):
                        completion(.failure(error))

                    case .success(.available):
            // حفظ طلب الإضافة اذا لم توجد علاقة سابقة
                        self.database.collection("companion_connections")
                            .addDocument(data: requestData) { error in
                                if let error {
                                    completion(.failure(error))
                                } else {
                                    completion(.success(()))
                                }
                            }

                    case .success:
            // ارجاع خطا عند وجود مرافق مضاف او طلب معلق
                        completion(.failure(CompanionRequestError.alreadyExists))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// يتحقق من حالة العلاقة بين مستخدمين لمعرفة هل هما مرافقان او لديهما طلب معلق
    func connectionStatus(
        between firstUsername: String,
        and secondUsername: String,
        // يعيد حالة العلاقة او الخطا عند فشل قراءة البيانات
        completion: @escaping (Result<CompanionConnectionStatus, Error>) -> Void
    ) {
        // تجهيز اسماء المستخدمين قبل فحص العلاقة بينهما
        let first = firstUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let second = secondUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // جلب علاقات وطلبات المرافقين من قاعدة البيانات
        database.collection("companion_connections").getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            // استخراج حالة العلاقة الخاصة بالمستخدمين
            let statuses = snapshot?.documents.compactMap { document -> String? in
                guard
                    let pilgrimUsername = document["pilgrimUsername"] as? String,
                    let companionUsername = document["companionUsername"] as? String,
                    let status = document["status"] as? String
                else {
                    return nil
                }
                // التاكد ان العلاقة تخص المستخدمين نفسهما مهما كان مرسل الطلب
                let isSamePair = (pilgrimUsername.lowercased() == first && companionUsername.lowercased() == second)
                    || (pilgrimUsername.lowercased() == second && companionUsername.lowercased() == first)
                return isSamePair ? status : nil
            } ?? []
            // تحديد حالة العلاقة بين المستخدمين
            if statuses.contains("accepted") {
                completion(.success(.accepted)) // المرافق مضاف بالفعل
            } else if statuses.contains("pending") {
                completion(.success(.pending)) // يوجد طلب اضافة معلق
            } else {
                completion(.success(.available)) // يمكن ارسال طلب اضافة جديد
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
    func fetchAcceptedCompanions(
        for username: String,
        completion: @escaping (Result<[Companion], Error>) -> Void
    ) {
        let fallbackUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let userID = Auth.auth().currentUser?.uid else {
            loadAcceptedCompanions(for: fallbackUsername, completion: completion)
            return
        }

        database.collection("users").document(userID).getDocument { document, _ in
            let savedUsername = document?.data()?["username"] as? String
            self.loadAcceptedCompanions(
                for: savedUsername ?? fallbackUsername,
                completion: completion
            )
        }
    }

    private func loadAcceptedCompanions(
        for username: String,
        completion: @escaping (Result<[Companion], Error>) -> Void
    ) {
        let normalizedUsername = username.lowercased()

        database.collection("companion_connections").getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }

            let companions = snapshot?.documents.compactMap { document -> Companion? in
                guard
                    let status = document["status"] as? String,
                    status == "accepted",
                    let pilgrimUsername = document["pilgrimUsername"] as? String,
                    let companionUsername = document["companionUsername"] as? String
                else {
                    return nil
                }

                if pilgrimUsername.lowercased() == normalizedUsername,
                   let companionName = document["companionName"] as? String,
                   let companionPhoneNumber = document["companionPhoneNumber"] as? String {
                    return Companion(
                        name: companionName,
                        username: companionUsername,
                        phoneNumber: companionPhoneNumber,
                        isAlertEnabled: document["isAlertEnabled"] as? Bool ?? true,
                        connectionId: document.documentID
                    )
                }

                if companionUsername.lowercased() == normalizedUsername,
                   let pilgrimName = document["pilgrimName"] as? String,
                   let pilgrimPhoneNumber = document["pilgrimPhoneNumber"] as? String {
                    return Companion(
                        name: pilgrimName,
                        username: pilgrimUsername,
                        phoneNumber: pilgrimPhoneNumber,
                        isAlertEnabled: document["isAlertEnabled"] as? Bool ?? true,
                        connectionId: document.documentID
                    )
                }

                return nil
            } ?? []

            completion(.success(self.removeDuplicateCompanions(companions)))
        }
    }
    
    /// يجلب المرافقين المقبولين الذين تنبيهاتهم مفعله لارسال تنبيه الطوارئ لهم
    func fetchEnabledCompanions(
        for pilgrimUsername: String,
        // يعيد قائمة المرافقين او الخطا عند فشل قراءة البيانات
        completion: @escaping (Result<[Companion], Error>) -> Void
    ) {
        // البحث عن علاقات المرافقين الخاصه بالمستخدم
        database.collection("companion_connections")
            .whereField("pilgrimUsername", isEqualTo: pilgrimUsername)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                // اختيار المرافقين المقبولين والمفعل عندهم التنبيه فقط
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
                    // تجهيز بيانات المرافق ليصل اليه تنبيه الطوارئ
                    return Companion(
                        name: companionName,
                        username: companionUsername,
                        phoneNumber: companionPhoneNumber,
                        isAlertEnabled: true,
                        connectionId: document.documentID
                    )
                } ?? []
                // ازالة اي مرافق مكرر ثم اعادة القائمه
                completion(.success(self.removeDuplicateCompanions(companions)))
            }
    }

    private func removeDuplicateCompanions(_ companions: [Companion]) -> [Companion] {
        var usernames = Set<String>()
        return companions.filter {
            usernames.insert($0.username.lowercased()).inserted
        }
    }
}

