import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

struct ParamedicProfileSettings {
    var username = ""
    var age = 0
    var firstName = ""
    var lastName = ""
    var email = ""
    private(set) var certificateFileName = ""

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    init() { }

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
final class ParamedicSettingsStore: ObservableObject {
    @Published var profile = ParamedicProfileSettings()
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let database = Firestore.firestore()
    private var savedUsername = ""

    // يجلب بيانات المسعف من فايرستور
    func fetch() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let userID = Auth.auth().currentUser?.uid else {
                throw ParamedicSettingsError.notSignedIn
            }

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

    /// يحفظ تعديلات بروفايل المسعف في فايرستور
    func saveProfile(newPassword: String = "") async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            guard let user = Auth.auth().currentUser else {
                throw ParamedicSettingsError.notSignedIn
            }

            /// يتأكد أن الإيميل الجديد تم التحقق منه قبل الحفظ
            try await user.reload()
            guard let verifiedUser = Auth.auth().currentUser,
                  verifiedUser.email?.normalizedEmail == profile.email.normalizedEmail
            else {
                throw ParamedicSettingsError.emailNotVerified
            }

            if !newPassword.isEmpty {
                try await verifiedUser.updatePassword(to: newPassword)
            }

            let oldUsernameKey = savedUsername.usernameKey
            let newUsernameKey = profile.username.usernameKey
            let userDocument = database.collection("users").document(verifiedUser.uid)

            /// يحفظ البيانات القابلة للتعديل فقط ولا يغير الشهادة
            let editableData: [String: Any] = [
                "username": profile.username.cleaned,
                "age": profile.age,
                "firstName": profile.firstName.cleaned,
                "lastName": profile.lastName.cleaned,
                "email": profile.email.cleaned.lowercased(),
                "updatedAt": FieldValue.serverTimestamp()
            ]

            /// يحدث بيانات اسم المستخدم أو ينشئ اسم جديد إذا تغير
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

                let newUsernameDocument = database.collection("usernames").document(newUsernameKey)
                guard !(try await newUsernameDocument.getDocument()).exists else {
                    throw ParamedicSettingsError.usernameTaken
                }

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

private enum ParamedicSettingsError: LocalizedError {
    case notSignedIn
    case profileNotFound
    case invalidUsername
    case usernameTaken
    case emailNotVerified

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Please log in again."
        case .profileNotFound: "Paramedic profile was not found."
        case .invalidUsername: "Username cannot be empty."
        case .usernameTaken: "Username is already taken."
        case .emailNotVerified: "Verify the new email before saving."
        }
    }
}

private extension String {
    var cleaned: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var usernameKey: String { cleaned.lowercased() }
}
