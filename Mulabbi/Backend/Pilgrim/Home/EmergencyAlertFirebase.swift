/// مسؤول عن حفظ بيانات طلبات الطوارئ وقراءتها من Firebase Firestore
import Foundation
import FirebaseFirestore
import CoreLocation

///ينشئ طلب طوارئ جديد ويحفظه في   emergency_alerts collection
final class EmergencyAlertFirebase {
    private let database = Firestore.firestore()
    
    func createEmergencyAlert(
        pilgrimUsername: String,
        description: String,
        isRequestForOther: Bool = false,
        ///هل تم إرسال طلب الطوارئ بنجاح او صار مشكلة اثناء الارسال
        completion: @escaping (Result<String, Error>) -> Void    ) {
        let alertReference = database.collection("emergency_alerts").document()

        let alertData: [String: Any] = [
            "alertId": alertReference.documentID,
            "description": description,
            "time": Timestamp(date: Date()),
            "PIUsername": pilgrimUsername,
            "PAUsername": NSNull(),
            "status": "pending",
            "isRequestForOther": isRequestForOther
        ]

        alertReference.setData(alertData) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(alertReference.documentID))
            }
        }
    }
    
    /// يحفظ موقع الحاج او المعتمر المرتبط بطلب طوارئ معين في Firebase Firestore
    func saveLocation(
        alertId: String,
        pilgrimUsername: String,
        latitude: Double,
        longitude: Double,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let locationData: [String: Any] = [
            "alertId": alertId,
            "PIUsername": pilgrimUsername,
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": Timestamp(date: Date())
        ]
        
        database.collection("locations").addDocument(data: locationData) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    /// يتابع حالة طلب الطوارئ ويبلغ الواجهه الرئيسيه عند تغييرها
    func observeAlertStatus(
        alertId: String,
        onStatusChanged: @escaping (String) -> Void
    ) {
        database.collection("emergency_alerts")
            .document(alertId)
            .addSnapshotListener { documentSnapshot, _ in
                guard let status = documentSnapshot?.data()?["status"] as? String else {
                    return
                }

                onStatusChanged(status)
            }
    }
    
    /// يحفظ اسماء المرافقين المفعلين الذين يجب ان يصلهم تنبيه طلب الطوارئ
    func saveCompanionRecipients(
        alertId: String,
        companionUsernames: [String]
    ) {
        database.collection("emergency_alerts")
            .document(alertId)
            .updateData([
                "companionUsernames": companionUsernames
            ])
    }
    
    /// يتابع طلبات الطوارئ الموجهة للمرافق في الداتابيس وعند وصول طلب جديد يرسل رقمه واسم مستخدم صاحبه الى التطبيق
    func receiveRequest(
        for companionUsername: String,
        onRequestReceived: @escaping (String, String) -> Void
    ) -> ListenerRegistration {
        database.collection("emergency_alerts")
            .whereField("companionUsernames", arrayContains: companionUsername)
            .addSnapshotListener { snapshot, _ in
                guard
                    let document = snapshot?.documents.first(where: {
                        ($0["status"] as? String ?? "pending") == "pending"
                    }),
                    let pilgrimUsername = document["PIUsername"] as? String
                else {
                    return
                }

                onRequestReceived(document.documentID, pilgrimUsername)
            }
    }
    /// يحضر احداثيات موقع صاحب طلب الطوارئ المرتبط بالطلب
    func fetchAlertLocation(
        alertId: String,
        completion: @escaping (Result<CLLocationCoordinate2D?, Error>) -> Void
    ) {
        database.collection("locations")
            .whereField("alertId", isEqualTo: alertId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error {
                    completion(.failure(error))
                    return
                }

                guard
                    let document = snapshot?.documents.first,
                    let latitude = document["latitude"] as? Double,
                    let longitude = document["longitude"] as? Double
                else {
                    completion(.success(nil))
                    return
                }

                let location = CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                )

                completion(.success(location))
            }
    }
}

