import Foundation
@preconcurrency import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    /// يحتفظ باحداثيات موقع المستخدم الحالي بعد السماح بالوصول للموقع
    @Published private(set) var currentLocation: CLLocationCoordinate2D?

    var onAuthorized: (() -> Void)?
    var onDenied: (() -> Void)?
    /// يستخدمه الهوم للتأكد ان موقع المستخدم وصل
    var onLocationReceived: ((CLLocationCoordinate2D) -> Void)?
    
    
    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    
    func requestPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            onAuthorized?()
        case .denied, .restricted:
            onDenied?()
        @unknown default:
            onDenied?()
        }
    }
    /// يطلب احداثيات موقع المستخدم عند ارسال طلب الطوارئ
    func requestCurrentLocation() {
        manager.requestLocation()
    }
    /// يبدأ تحديث موقع المرافق اثناء فتح الخريطة لتحديث المسافة الى صاحب طلب الطوارئ
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    /// يوقف تحديث موقع المرافق عند اغلاق الخريطه
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.onAuthorized?()
            case .denied, .restricted:
                self.onDenied?()
            case .notDetermined:
                break
            @unknown default:
                self.onDenied?()
            }
        }
    }
    /// ياخذ الموقع الذي ارسله الجهاز ويرسله الى الصفحه الرئيسيه
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let coordinate = locations.last?.coordinate else { return }
        currentLocation = coordinate
        onLocationReceived?(coordinate)    }
    
    /// يتعامل مع فشل الحصول على موقع المستخدم من الجهاز
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
}
