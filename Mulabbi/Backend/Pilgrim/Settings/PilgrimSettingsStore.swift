import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

/// بيانات الملف الشخصي للحاج اللي تظهر في صفحة الإعدادات
struct PilgrimProfileSettings {
    var username = ""
    var age = 0
    var firstName = ""
    var lastName = ""
    var email = ""
    var phoneNumber = ""
    var nationality = ""
    var languages: [String] = []

    /// يجمع الاسم الاول واسم العائلة عشان يظهر الاسم كامل
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// بيانات السجل الطبي للحاج
struct PilgrimMedicalSettings {
    var bloodType = ""
    var gender = ""
    var chronicDiseases = ""
    var medications = ""
    var allergies = ""
    var otherInfo = ""
}

@MainActor
/// مسؤول عن جلب بيانات الحاج وحفظ تعديلاته في قاعدة البيانات
final class PilgrimSettingsStore: ObservableObject {
    @Published var profile = PilgrimProfileSettings()
    @Published var medicalRecord = PilgrimMedicalSettings()
    private var isLoading = false
    private var isSaving = false
    @Published private(set) var errorMessage: String?

    private let database = Firestore.firestore()
    private var savedUsername = ""

    /// يجلب بيانات الحاج وسجله الطبي من قاعدة البيانات ثم يعرضها في الإعدادات
    func fetch() async {
        /// يمنع تكرار طلب الجلب اذا كان الطلب السابق ما انتهى
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            /// يجلب بيانات الحساب الحالي ويتأكد انه حساب حاج
            let data = try await currentUserData()

            /// يحول البيانات المحفوظة الى بيانات تظهر في الملف الشخصي والسجل الطبي
            profile = PilgrimProfileSettings(data: data)
            profile.email = Auth.auth().currentUser?.email ?? profile.email
            medicalRecord = PilgrimMedicalSettings(
                data: data["medicalRecord"] as? [String: Any] ?? [:]
            )
            savedUsername = profile.username
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// يجلب عمر الحاج من قاعدة البيانات لاستخدامه في متابعة نبض القلب
    func fetchAge() async throws -> Int {
        let data = try await currentUserData()
        guard let age = (data["age"] as? NSNumber)?.intValue,
              age >= 15
        else {
            throw PilgrimSettingsError.invalidAge
        }
        return age
    }

    /// يحفظ تعديلات الملف الشخصي للحاج وكلمة المرور الجديدة اذا كتبها
    func saveProfile(newPassword: String) async -> Bool {
        /// يمنع تكرار الحفظ اذا كان الطلب السابق ما انتهى
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            /// يتأكد ان المستخدم مسجل قبل حفظ التعديلات
            guard let user = Auth.auth().currentUser else {
                throw PilgrimSettingsError.notSignedIn
            }

            /// يتأكد ان البريد الجديد صار بريد الحساب قبل ما يحفظه
            try await user.reload()
            guard let verifiedUser = Auth.auth().currentUser,
                  verifiedUser.email?.normalizedEmail == profile.email.normalizedEmail
            else {
                throw PilgrimSettingsError.emailNotVerified
            }

            /// اذا كتب المستخدم كلمة مرور جديدة يحدثها في الحساب
            if !newPassword.isEmpty {
                try await verifiedUser.updatePassword(to: newPassword)
            }

            /// يجهز بيانات الملف الشخصي بالشكل المطلوب للحفظ
            let oldUsernameKey = savedUsername.usernameKey
            let newUsernameKey = profile.username.usernameKey
            let userDocument = database.collection("users").document(verifiedUser.uid)
            var profileData = profile.firestoreData
            profileData["updatedAt"] = FieldValue.serverTimestamp()

            /// يحفظ التعديلات ويحدث بيانات اسم المستخدم اذا تغير
            if oldUsernameKey == newUsernameKey {
                let batch = database.batch()
                batch.setData(profileData, forDocument: userDocument, merge: true)
                batch.setData([
                    "email": verifiedUser.email ?? profile.email,
                    "uid": verifiedUser.uid,
                    "role": "pilgrim"
                ], forDocument: database.collection("usernames").document(newUsernameKey), merge: true)
                try await batch.commit()
            } else {
                try await changeUsername(
                    from: oldUsernameKey,
                    to: newUsernameKey,
                    loginEmail: verifiedUser.email ?? profile.email,
                    userID: verifiedUser.uid,
                    userData: profileData
                )
            }

            try await updateCompanionConnections(
                from: savedUsername,
                to: profile.username,
                name: profile.fullName,
                phoneNumber: profile.phoneNumber
            )
            savedUsername = profile.username
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// يحفظ تعديلات السجل الطبي للحاج في قاعدة البيانات
    func saveMedicalRecord() async -> Bool {
        /// يمنع تكرار الحفظ اذا كان الطلب السابق ما انتهى
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            /// يتأكد ان المستخدم مسجل قبل حفظ السجل الطبي
            guard let userID = Auth.auth().currentUser?.uid else {
                throw PilgrimSettingsError.notSignedIn
            }

            /// يحفظ السجل الطبي داخل بيانات الحاج
            try await database.collection("users").document(userID).setData([
                "medicalRecord": medicalRecord.firestoreData,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// يجلب بيانات المستخدم الحالي ويتأكد ان نوع الحساب صحيح
    private func currentUserData() async throws -> [String: Any] {
        /// يتأكد ان المستخدم مسجل قبل جلب البيانات
        guard let userID = Auth.auth().currentUser?.uid else {
            throw PilgrimSettingsError.notSignedIn
        }

        let snapshot = try await database.collection("users").document(userID).getDocument()
        guard let data = snapshot.data(), data["role"] as? String == "pilgrim" else {
            throw PilgrimSettingsError.profileNotFound
        }
        return data
    }

    /// يتأكد ان اسم المستخدم الجديد مو مستخدم من حساب ثاني ثم يحفظه
    private func changeUsername(
        from oldKey: String,
        to newKey: String,
        loginEmail: String,
        userID: String,
        userData: [String: Any]
    ) async throws {
        guard !newKey.isEmpty else { throw PilgrimSettingsError.invalidUsername }

        /// يبحث عن اسم المستخدم الجديد قبل ما يحفظه
        let newUsernameDocument = database.collection("usernames").document(newKey)
        guard !(try await newUsernameDocument.getDocument()).exists else {
            throw PilgrimSettingsError.usernameTaken
        }

        /// يحفظ الملف الشخصي واسم المستخدم الجديد مع بعض
        let batch = database.batch()
        batch.setData(userData, forDocument: database.collection("users").document(userID), merge: true)
        batch.setData([
            "email": loginEmail,
            "uid": userID,
            "role": "pilgrim"
        ], forDocument: newUsernameDocument)

        if !oldKey.isEmpty {
            batch.deleteDocument(database.collection("usernames").document(oldKey))
        }
        try await batch.commit()
    }

    private func updateCompanionConnections(
        from oldUsername: String,
        to newUsername: String,
        name: String,
        phoneNumber: String
    ) async throws {
        let oldUsername = oldUsername.cleaned
        guard !oldUsername.isEmpty else { return }

        async let sentRequests = database.collection("companion_connections")
            .whereField("pilgrimUsername", isEqualTo: oldUsername)
            .getDocuments()
        async let receivedRequests = database.collection("companion_connections")
            .whereField("companionUsername", isEqualTo: oldUsername)
            .getDocuments()

        let (sentSnapshot, receivedSnapshot) = try await (sentRequests, receivedRequests)
        let cleanedUsername = newUsername.cleaned
        let cleanedName = name.cleaned
        let cleanedPhoneNumber = phoneNumber.cleaned
        var references: [String: DocumentReference] = [:]
        var updates: [String: [String: Any]] = [:]

        for document in sentSnapshot.documents {
            references[document.documentID] = document.reference
            updates[document.documentID] = [
                "pilgrimUsername": cleanedUsername,
                "pilgrimName": cleanedName,
                "pilgrimPhoneNumber": cleanedPhoneNumber
            ]
        }

        for document in receivedSnapshot.documents {
            references[document.documentID] = document.reference
            updates[document.documentID, default: [:]].merge([
                "companionUsername": cleanedUsername,
                "companionName": cleanedName,
                "companionPhoneNumber": cleanedPhoneNumber
            ]) { _, new in new }
        }

        guard !updates.isEmpty else { return }

        let batch = database.batch()
        for (documentID, data) in updates {
            if let reference = references[documentID] {
                batch.updateData(data, forDocument: reference)
            }
        }
        try await batch.commit()
    }
}

/// الاخطاء اللي ممكن تصير وقت جلب بيانات الحاج أو حفظها
private enum PilgrimSettingsError: LocalizedError {
    case notSignedIn
    case profileNotFound
    case invalidAge
    case invalidUsername
    case usernameTaken
    case emailNotVerified

    /// يحول الخطأ الى رسالة تظهر للمستخدم
    var errorDescription: String? {
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let locale = Locale(identifier: language)

        switch self {
        case .notSignedIn:
            return String(localized: "Please log in again.", locale: locale)
        case .profileNotFound:
            return String(localized: "Pilgrim profile was not found.", locale: locale)
        case .invalidAge:
            return String(localized: "A valid age was not found in the pilgrim profile.", locale: locale)
        case .invalidUsername:
            return String(localized: "Username cannot be empty.", locale: locale)
        case .usernameTaken:
            return String(localized: "Username is already taken.", locale: locale)
        case .emailNotVerified:
            return String(localized: "Verify the new email before saving.", locale: locale)
        }
    }
}

private extension PilgrimProfileSettings {
    /// يحول بيانات الحساب الى بيانات الملف الشخصي
    init(data: [String: Any]) {
        username = data["username"] as? String ?? ""
        age = (data["age"] as? NSNumber)?.intValue ?? 0
        firstName = data["firstName"] as? String ?? ""
        lastName = data["lastName"] as? String ?? ""
        email = data["email"] as? String ?? ""
        phoneNumber = data["phoneNumber"] as? String ?? ""
        nationality = data["nationality"] as? String ?? ""
        languages = data["languages"] as? [String] ?? []
    }

    /// يجهز بيانات الملف الشخصي بالشكل المطلوب للحفظ في قاعدة البيانات
    var firestoreData: [String: Any] {
        [
            "username": username.cleaned,
            "age": age,
            "firstName": firstName.cleaned,
            "lastName": lastName.cleaned,
            "email": email.cleaned.lowercased(),
            "phoneNumber": phoneNumber.cleaned,
            "nationality": nationality.cleaned,
            "languages": languages
        ]
    }
}

private extension PilgrimMedicalSettings {
    /// يحول بيانات قاعدة البيانات الى بيانات السجل الطبي
    init(data: [String: Any]) {
        bloodType = data["bloodType"] as? String ?? ""
        gender = data["gender"] as? String ?? ""
        chronicDiseases = data["chronicDiseases"] as? String ?? ""
        medications = data["medications"] as? String ?? ""
        allergies = data["allergies"] as? String ?? ""
        otherInfo = data["otherInfo"] as? String ?? ""
    }

    /// يجهز بيانات السجل الطبي بالشكل المطلوب للحفظ في قاعدة البيانات
    var firestoreData: [String: Any] {
        [
            "bloodType": bloodType.cleaned,
            "gender": gender.cleaned,
            "chronicDiseases": chronicDiseases.cleaned,
            "medications": medications.cleaned,
            "allergies": allergies.cleaned,
            "otherInfo": otherInfo.cleaned
        ]
    }
}

private extension String {
    /// يحذف المسافات الزائدة من بداية النص ونهايته
    var cleaned: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// يوحد شكل اسم المستخدم عشان يسهل البحث عنه
    var usernameKey: String { cleaned.lowercased() }
}
