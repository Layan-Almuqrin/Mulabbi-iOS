import SwiftUI
import MapKit
import Combine

@MainActor
final class ParamedicMapRoute: ObservableObject {
    @Published private(set) var paramedicLocation: CLLocationCoordinate2D?
    @Published private(set) var initialRegion: MKCoordinateRegion?

    private let locationManager = LocationManager()
    private var destination: CLLocationCoordinate2D?
    private var hasFramedLocations = false

    func start(to destination: CLLocationCoordinate2D?) {
        stop()
        paramedicLocation = nil
        updateDestination(destination)
        locationManager.onAuthorized = { [weak self] in
            self?.locationManager.startUpdatingLocation()
        }
        locationManager.onDenied = { [weak self] in
            self?.locationManager.stopUpdatingLocation()
            self?.paramedicLocation = nil
        }
        locationManager.onLocationReceived = { [weak self] coordinate in
            self?.receive(coordinate)
        }
        locationManager.requestPermission()
    }

    func updateDestination(_ coordinate: CLLocationCoordinate2D?) {
        initialRegion = nil
        hasFramedLocations = false
        destination = coordinate.flatMap { CLLocationCoordinate2DIsValid($0) ? $0 : nil }
        if let paramedicLocation { receive(paramedicLocation) }
    }

    func stop() {
        locationManager.onAuthorized = nil
        locationManager.onDenied = nil
        locationManager.onLocationReceived = nil
        locationManager.stopUpdatingLocation()
        destination = nil
    }

    private func receive(_ coordinate: CLLocationCoordinate2D) {
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        paramedicLocation = coordinate
        guard let destination else { return }
       // اول ما نعرف موقع المسعف نضبط زوم الخريطة عشان يبان مكانه ومكان البلاغ مع بعض
        if !hasFramedLocations {
            initialRegion = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: max(abs(coordinate.latitude - destination.latitude) * 2.4, 0.018),
                    longitudeDelta: max(abs(coordinate.longitude - destination.longitude) * 2.4, 0.018)
                )
            )
            hasFramedLocations = true
        }
    }
}

// نبين مكان المسعف على الخريطة بدائرة بيضاء
struct ParamedicRouteOverlay: MapContent {
    @ObservedObject var route: ParamedicMapRoute

    var body: some MapContent {
        if let coordinate = route.paramedicLocation {
            Annotation("Paramedic location", coordinate: coordinate) {
                CompanionCurrentLocationMarker()
            }
        }
    }
}
