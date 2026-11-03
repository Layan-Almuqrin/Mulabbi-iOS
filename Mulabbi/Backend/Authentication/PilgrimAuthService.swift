//
//  Created by Yara Alsunbul on 18/05/1448 AH.
//
import FirebaseAuth
import FirebaseFirestore

enum PilgrimAuthError: LocalizedError {
    case usernameNotFound
    case emailNotVerified

    var errorDescription: String? {
        switch self {
        case .usernameNotFound:
            return "اسم المستخدم غير موجود"
        case .emailNotVerified:
            return "تحققي من بريدك الإلكتروني أولاً"
        }
    }
}

enum PilgrimAuthService {
    static func login(username: String, password: String) async throws {
        let usernameKey = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let snapshot = try await Firestore.firestore()
            .collection("usernames")
            .document(usernameKey)
            .getDocument()

        guard let email = snapshot.data()?["email"] as? String else {
            throw PilgrimAuthError.usernameNotFound
        }

        let result = try await Auth.auth()
            .signIn(withEmail: email, password: password)

        guard result.user.isEmailVerified else {
            try Auth.auth().signOut()
            throw PilgrimAuthError.emailNotVerified
        }
    }
}
