import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

/// بيانات الملف الشخصي للمسعف اللي تظهر في صفحة الإعدادات
struct ParamedicProfileSettings {
    var username = ""
    var age = 0
    var firstName = ""
    var lastName = ""
    var email = ""
    private(set) var certificateFileName = ""

    /// يجمع الاسم الاول واسم العائلة عشان يظهر الاسم كامل
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// ينشئ ملف شخصي فاضي قبل جلب البيانات
    init() { }

    /// ينشئ الملف الشخصي بالبيانات المرسلة
    init(
        username: String,
        age: Int,
        firstName: String,
        lastName: String,
        email: String,
        certificateFileName: String
    ) {
        self.username = username
        self.age = age
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.certificateFileName = certificateFileName
    }

    /// يحول بيانات الحساب الى بيانات الملف الشخصي
    init(data: [String: Any]) {
        username = data["username"] as? String ?? ""
        age = (data["age"] as? NSNumber)?.intValue ?? 0
        firstName = data["firstName"] as? String ?? ""
        lastName = data["lastName"] as? String ?? ""
        email = data["email"] as? String ?? ""
        certificateFileName = data["certificateFileName"] as? String ?? ""
    }
}

@MainActor
/// مسؤول عن جلب بيانات المسعف وحفظ تعديلاته في قاعدة البيانات
final class ParamedicSettingsStore: ObservableObject {
    @Published var profile = ParamedicProfileSettings()
    private var isLoading = false
    private var isSaving = false
    @Published private(set) var errorMessage: String?

    private let database = Firestore.firestore()
    private var savedUsername = ""

    /// يجلب بيانات المسعف من قاعدة البيانات ثم يعرضها في الإعدادات
    func fetch() async {
        /// يمنع تكرار طلب الجلب اذا كان الطلب السابق ما انتهى
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            /// يتأكد ان المستخدم مسجل قبل جلب البيانات
            guard let userID = Auth.auth().currentUser?.uid else {
                throw ParamedicSettingsError.notSignedIn
            }

            /// يجلب البيانات ويتأكد انها لحساب مسعف
            let snapshot = try await database.collection("users").document(userID).getDocument()
            guard let data = snapshot.data(), data["role"] as? String == "paramedic" else {
                throw ParamedicSettingsError.profileNotFound
            }

            profile = ParamedicProfileSettings(data: data)
            profile.email = Auth.auth().currentUser?.email ?? profile.email
            savedUsername = profile.username
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// يحفظ تعديلات الملف الشخصي للمسعف وكلمة المرور الجديدة اذا كتبها
    func saveProfile(newPassword: String) async -> Bool {
        /// يمنع تكرار الحفظ اذا كان الطلب السابق ما انتهى
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            /// يتأكد ان المستخدم مسجل قبل حفظ التعديلات
            guard let user = Auth.auth().currentUser else {
                throw ParamedicSettingsError.notSignedIn
            }

            /// يتأكد ان البريد الجديد صار بريد الحساب قبل ما يحفظه
            try await user.reload()
            guard let verifiedUser = Auth.auth().currentUser,
                  verifiedUser.email?.normalizedEmail == profile.email.normalizedEmail
            else {
                throw ParamedicSettingsError.emailNotVerified
            }

            /// اذا كتب المستخدم كلمة مرور جديدة يحدثها في الحساب
            if !newPassword.isEmpty {
                try await verifiedUser.updatePassword(to: newPassword)
            }

            /// يجهز اسم المستخدم القديم والجديد عشان يعرف اذا تغير
            let oldUsernameKey = savedUsername.usernameKey
            let newUsernameKey = profile.username.usernameKey
            let userDocument = database.collection("users").document(verifiedUser.uid)

            /// يجهز البيانات اللي يقدر المسعف يعدلها بدون ما يغير الشهادة
            let editableData: [String: Any] = [
                "username": profile.username.cleaned,
                "age": profile.age,
                "firstName": profile.firstName.cleaned,
                "lastName": profile.lastName.cleaned,
                "email": profile.email.cleaned.lowercased(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            /// يحفظ التعديلات ويحدث بيانات اسم المستخدم اذا تغير
            if oldUsernameKey == newUsernameKey {
                let batch = database.batch()
                batch.setData(editableData, forDocument: userDocument, merge: true)
                batch.setData([
                    "email": verifiedUser.email ?? profile.email,
                    "uid": verifiedUser.uid,
                    "role": "paramedic"
                ], forDocument: database.collection("usernames").document(newUsernameKey), merge: true)
                try await batch.commit()
            } else {
                guard !newUsernameKey.isEmpty else {
                    throw ParamedicSettingsError.invalidUsername
                }

                /// يبحث عن اسم المستخدم الجديد قبل ما يحفظه
                let newUsernameDocument = database.collection("usernames").document(newUsernameKey)
                guard !(try await newUsernameDocument.getDocument()).exists else {
                    throw ParamedicSettingsError.usernameTaken
                }

                /// يحفظ الملف الشخصي واسم المستخدم الجديد مع بعض
                let batch = database.batch()
                batch.setData(editableData, forDocument: userDocument, merge: true)
                batch.setData([
                    "email": verifiedUser.email ?? profile.email,
                    "uid": verifiedUser.uid,
                    "role": "paramedic",
                    "certificateStatus": "appears_eligible"
                ], forDocument: newUsernameDocument)

                if !oldUsernameKey.isEmpty {
                    batch.deleteDocument(database.collection("usernames").document(oldUsernameKey))
                }
                try await batch.commit()
            }

            savedUsername = profile.username
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

/// الاخطاء اللي ممكن تصير وقت جلب بيانات المسعف أو حفظها
private enum ParamedicSettingsError: LocalizedError {
    case notSignedIn
    case profileNotFound
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
            return String(localized: "Paramedic profile was not found.", locale: locale)
        case .invalidUsername:
            return String(localized: "Username cannot be empty.", locale: locale)
        case .usernameTaken:
            return String(localized: "Username is already taken.", locale: locale)
        case .emailNotVerified:
            return String(localized: "Verify the new email before saving.", locale: locale)
        }
    }
}

private extension String {
    /// يحذف المسافات الزائدة من بداية النص ونهايته
    var cleaned: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// يوحد شكل اسم المستخدم عشان يسهل البحث عنه
    var usernameKey: String { cleaned.lowercased() }
}
