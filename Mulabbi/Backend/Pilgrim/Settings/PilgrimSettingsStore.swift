import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

struct PilgrimProfileSettings {
    var username = ""
    var age = 0
    var firstName = ""
    var lastName = ""
    var email = ""
    var phoneNumber = ""
    var nationality = ""
    var languages: [String] = []

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct PilgrimMedicalSettings {
    var bloodType = ""
    var gender = ""
    var chronicDiseases = ""
    var medications = ""
    var allergies = ""
    var otherInfo = ""
}

@MainActor
final class PilgrimSettingsStore: ObservableObject {
    @Published var profile = PilgrimProfileSettings()
    @Published var medicalRecord = PilgrimMedicalSettings()
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    @Published private(set) var errorMessage: String?

    private let database = Firestore.firestore()
    private var savedUsername = ""

    /// يجلب بيانات الحاج وسجله الطبي من فايرستور
    func fetch() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let data = try await currentUserData(expectedRole: "pilgrim")
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

    /// يجلب عمر الحاج لاستخدامه في متابعة نبض القلب
    func fetchAge() async throws -> Int {
        let data = try await currentUserData(expectedRole: "pilgrim")
        guard let age = (data["age"] as? NSNumber)?.intValue,
              age >= 15
        else {
            throw PilgrimSettingsError.invalidAge
        }
        return age
    }

    /// يحفظ تعديلات بروفايل الحاج في فايرستور
    func saveProfile(newPassword: String = "") async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            guard let user = Auth.auth().currentUser else {
                throw PilgrimSettingsError.notSignedIn
            }

            /// يتأكد أن الإيميل الجديد تم التحقق منه قبل الحفظ
            try await user.reload()
            guard let verifiedUser = Auth.auth().currentUser,
                  verifiedUser.email?.normalizedEmail == profile.email.normalizedEmail
            else {
                throw PilgrimSettingsError.emailNotVerified
            }

            if !newPassword.isEmpty {
                try await verifiedUser.updatePassword(to: newPassword)
            }

            let oldUsernameKey = savedUsername.usernameKey
            let newUsernameKey = profile.username.usernameKey
            let userDocument = database.collection("users").document(verifiedUser.uid)
            var profileData = profile.firestoreData
            profileData["updatedAt"] = FieldValue.serverTimestamp()

            /// يحدث بيانات اسم المستخدم أو ينشئ اسم جديد إذا تغير
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
                    role: "pilgrim",
                    loginEmail: verifiedUser.email ?? profile.email,
                    userID: verifiedUser.uid,
                    userData: profileData
                )
            }

            savedUsername = profile.username
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// يحفظ تعديلات السجل الطبي للحاج
    func saveMedicalRecord() async -> Bool {
        guard !isSaving else { return false }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            guard let userID = Auth.auth().currentUser?.uid else {
                throw PilgrimSettingsError.notSignedIn
            }

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

    private func currentUserData(expectedRole: String) async throws -> [String: Any] {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw PilgrimSettingsError.notSignedIn
        }

        let snapshot = try await database.collection("users").document(userID).getDocument()
        guard let data = snapshot.data(), data["role"] as? String == expectedRole else {
            throw PilgrimSettingsError.profileNotFound
        }
        return data
    }

    private func changeUsername(
        from oldKey: String,
        to newKey: String,
        role: String,
        loginEmail: String,
        userID: String,
        userData: [String: Any]
    ) async throws {
        guard !newKey.isEmpty else { throw PilgrimSettingsError.invalidUsername }

        let newUsernameDocument = database.collection("usernames").document(newKey)
        guard !(try await newUsernameDocument.getDocument()).exists else {
            throw PilgrimSettingsError.usernameTaken
        }

        let batch = database.batch()
        batch.setData(userData, forDocument: database.collection("users").document(userID), merge: true)
        batch.setData([
            "email": loginEmail,
            "uid": userID,
            "role": role
        ], forDocument: newUsernameDocument)

        if !oldKey.isEmpty {
            batch.deleteDocument(database.collection("usernames").document(oldKey))
        }
        try await batch.commit()
    }
}

private enum PilgrimSettingsError: LocalizedError {
    case notSignedIn
    case profileNotFound
    case invalidAge
    case invalidUsername
    case usernameTaken
    case emailNotVerified

    var errorDescription: String? {
        switch self {
        case .notSignedIn: "Please log in again."
        case .profileNotFound: "Pilgrim profile was not found."
        case .invalidAge: "A valid age was not found in the pilgrim profile."
        case .invalidUsername: "Username cannot be empty."
        case .usernameTaken: "Username is already taken."
        case .emailNotVerified: "Verify the new email before saving."
        }
    }
}

private extension PilgrimProfileSettings {
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
    init(data: [String: Any]) {
        bloodType = data["bloodType"] as? String ?? ""
        gender = data["gender"] as? String ?? ""
        chronicDiseases = data["chronicDiseases"] as? String ?? ""
        medications = data["medications"] as? String ?? ""
        allergies = data["allergies"] as? String ?? ""
        otherInfo = data["otherInfo"] as? String ?? ""
    }

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
    var cleaned: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var usernameKey: String { cleaned.lowercased() }
}
