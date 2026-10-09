import Foundation
@preconcurrency import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    var onAuthorized: (() -> Void)?
    var onDenied: (() -> Void)?

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
}
