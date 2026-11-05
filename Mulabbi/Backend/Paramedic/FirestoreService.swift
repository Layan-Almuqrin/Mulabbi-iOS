import Foundation
import FirebaseFirestore

final class FirestoreService {
    
    static let shared = FirestoreService()
    
    private let database: Firestore
    
    
    // يجهّز الاتصال بقاعدة بيانات Firestore.
    private init() {
        database = Firestore.firestore()
    }
    
    
    // MARK: - Read Documents
    
    // يرجع جميع مستندات المجموعة المحددة.
    func fetchDocuments(
        from collectionName: String
    ) async throws -> [QueryDocumentSnapshot] {
        
        let snapshot = try await database
            .collection(collectionName)
            .getDocuments()
        
        return snapshot.documents
    }
    
    
    // MARK: - Emergency Alerts
    
    // يقرأ مستندات مجموعة البلاغات المحددة.
    func fetchEmergencyAlerts(
        from collectionName: String
    ) async throws -> [QueryDocumentSnapshot] {
        
        let snapshot = try await database
            .collection(collectionName)
            .getDocuments()
        
        return snapshot.documents
    }
    
    
    // MARK: - Update Document
    
    // يحدّث الحقول المرسلة داخل المستند المحدد.
    func updateDocument(
        collectionName: String,
        documentID: String,
        data: [String: Any]
    ) async throws {
        
        try await database
            .collection(collectionName)
            .document(documentID)
            .updateData(data)
    }
    

    func createDocument(
        collectionName: String,
        documentID: String,
        data: [String: Any]
    ) async throws {
        
        try await database
            .collection(collectionName)
            .document(documentID)
            .setData(data)
    }
    
    
   
    
    
    func deleteDocument(
        collectionName: String,
        documentID: String
    ) async throws {
        
        try await database
            .collection(collectionName)
            .document(documentID)
            .delete()
    }
}
