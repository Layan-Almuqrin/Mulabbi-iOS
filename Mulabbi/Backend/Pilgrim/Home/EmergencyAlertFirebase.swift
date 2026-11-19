/// مسؤول عن حفظ بيانات طلبات الطوارئ وقراءتها من Firebase Firestore
import Foundation
import FirebaseFirestore
import CoreLocation

///ينشئ طلب طوارئ جديد ويحفظه في   emergency_alerts collection
final class EmergencyAlertFirebase {
    private let database = Firestore.firestore()
    
    /// ينشئ طلب طوارئ جديد ويحفظ بياناته في قاعدة البيانات
    func createEmergencyAlert(
        pilgrimUsername: String,
        description: String,
        isRequestForOther: Bool = false,
    // يعيد نتيجة الارسال رقم الطلب عند النجاح او الخطأ عند الفشل
        completion: @escaping (Result<String, Error>) -> Void    ) {
    // إنشاء طلب طوارئ جديد
        let alertReference = database.collection("emergency_alerts").document()

    // تجهيز معلومات طلب الطوارئ
        let alertData: [String: Any] = [
            "alertId": alertReference.documentID,
            "description": description,
            "time": Timestamp(date: Date()),
            "PIUsername": pilgrimUsername,
            "PAUsername": NSNull(),
            "status": "pending",
            "isRequestForOther": isRequestForOther
        ]
    // حفظ طلب الطوارئ في قاعدة البيانات
            alertReference.setData(alertData) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(alertReference.documentID))
            }
        }
    }
    
    /// يحفظ موقع المستخدم المرتبط بطلب طوارئ معين في قاعدة البيانات
    func saveLocation(
        alertId: String,
        pilgrimUsername: String,
        latitude: Double,
        longitude: Double,
    // يعيد نجاح الحفظ او الخطأ عند الفشل
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
    // تجهيز معلومات موقع المستخدم
        let locationData: [String: Any] = [
            "alertId": alertId,
            "PIUsername": pilgrimUsername,
            "latitude": latitude,
            "longitude": longitude,
            "timestamp": Timestamp(date: Date())
        ]
    // حفظ موقع المستخدم في قاعدة البيانات
        database.collection("locations").addDocument(data: locationData) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

 /// يتابع تغير حالة طلب الطوارئ ويرسل الحالة الجديدة للواجهة
    func observeAlertStatus(
        alertId: String,
 // يعيد الحالة الجديدة عند تغيرها
        onStatusChanged: @escaping (String) -> Void
    ) {
 // الوصول الى طلب الطوارئ باستخدام رقم الطلب
        database.collection("emergency_alerts")
            .document(alertId)
 // متابعة اي تغيير يحدث على حالة طلب الطوارئ مباشرة
            .addSnapshotListener { documentSnapshot, _ in
 // التأكد من وجود حالة لطلب الطوارئ
                guard let status = documentSnapshot?.data()?["status"] as? String else {
                    return
                }
// ارسال الحالة الجديدة للواجهة لتحديث التنبيه
                onStatusChanged(status)
            }
    }
    
    /// يحفظ اسماء المرافقين المفعلين الذين يجب ان يصلهم تنبيه طلب الطوارئ
    func saveCompanionRecipients(
        alertId: String,
        companionUsernames: [String]
    ) {
        // الوصول الى طلب الطوارئ باستخدام رقم الطلب
        database.collection("emergency_alerts")
            .document(alertId)
        // حفظ اسماء المرافقين الذين سيصلهم تنبيه الطوارئ
            .updateData([
                "companionUsernames": companionUsernames
            ])
    }
    
    /// يتابع طلبات الطوارئ الموجهة للمرافق ويعيد رقم الطلب واسم مرسله
     func receiveRequest(
        for companionUsername: String,
        // يعيد رقم طلب الطوارئ واسم المستخدم الذي ارسله
        onRequestReceived: @escaping (String, String) -> Void
    ) -> ListenerRegistration {
        // البحث عن طلبات الطوارئ الموجهة لهذا المرافق
        database.collection("emergency_alerts")
            .whereField("companionUsernames", arrayContains: companionUsername)
        // متابعة طلبات الطوارئ الجديدة مباشره
            .addSnapshotListener { snapshot, _ in
                // اختيار طلب طوارئ موجه للمرافق سواء كان ينتظر او قبله المسعف
                guard
                    let document = snapshot?.documents.first(where: {
                        guard let status = $0["status"] as? String else {
                            return false
                        }

                        return status == "pending" || status == "accepted"
                    }),
                    let pilgrimUsername = document["PIUsername"] as? String
                else {
                    return
                }
                // ارسال رقم الطلب واسم مرسله للتطبيق لاظهار التنبيه
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

