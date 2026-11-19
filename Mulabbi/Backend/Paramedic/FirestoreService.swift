import Foundation
import FirebaseFirestore

final class FirestoreService {
    
    static let shared = FirestoreService()
    
    private let database: Firestore
    
    
    // يجهّز الاتصال بقاعدة بيانات Firestore
    private init() {
        database = Firestore.firestore()
    }
    
    
    // نجيب كل السجلات من المجموعة اللي نحددها
  
        func fetchDocuments(
        from collectionName: String
    ) async throws -> [QueryDocumentSnapshot] {
        
        let snapshot = try await database
            .collection(collectionName)
            .getDocuments()
        
        return snapshot.documents
    }
    
    // نجيب بيانات البلاغات من المجموعة اللي حددناها
 
    func fetchEmergencyAlerts(
        from collectionName: String
    ) async throws -> [QueryDocumentSnapshot] {
        
        let snapshot = try await database
            .collection(collectionName)
            .getDocuments()
        
        return snapshot.documents
    }
    
    
   
    
// نختار السجل اللي نبي نعدله ونغير فيه بس الخانات اللي نحددها
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
