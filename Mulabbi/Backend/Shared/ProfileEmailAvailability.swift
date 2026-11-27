import FirebaseAuth
import FirebaseFirestore

enum ProfileEmailAvailability {
    static func isAvailable(_ email: String) async throws -> Bool {
        let currentUserID = Auth.auth().currentUser?.uid
        let documents = try await Firestore.firestore()
            .collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()
            .documents

        return !documents.contains { $0.documentID != currentUserID }
    }
}
