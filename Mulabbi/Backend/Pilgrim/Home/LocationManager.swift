import Foundation
@preconcurrency import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    var onAuthorized: (() -> Void)?
    var onDenied: (() -> Void)?
    var onInitialPermissionDenied: (() -> Void)?
    var onLocationReceived: ((CLLocationCoordinate2D) -> Void)?
    var onLocationRequestFailed: (() -> Void)?

    private var awaitingInitialAuthorizationDecision = false
    private var permissionWasRequested = false
    
    
    override init() {
        super.init()
        manager.delegate = self
    }

    
    func requestPermission() {
        permissionWasRequested = true

        switch manager.authorizationStatus {
        case .notDetermined:
            awaitingInitialAuthorizationDecision = true
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            permissionWasRequested = false
            onAuthorized?()
        case .denied, .restricted:
            permissionWasRequested = false
            onDenied?()
        @unknown default:
            permissionWasRequested = false
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
            guard self.permissionWasRequested else { return }

            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.awaitingInitialAuthorizationDecision = false
                self.permissionWasRequested = false
                self.onAuthorized?()
            case .denied, .restricted:
                let wasInitialDecision = self.awaitingInitialAuthorizationDecision
                self.awaitingInitialAuthorizationDecision = false
                self.permissionWasRequested = false

                if wasInitialDecision {
                    self.onInitialPermissionDenied?()
                } else {
                    self.onDenied?()
                }
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
        onLocationReceived?(coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationRequestFailed?()
    }
}
