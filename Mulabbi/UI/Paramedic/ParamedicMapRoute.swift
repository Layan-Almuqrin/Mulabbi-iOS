import SwiftUI
import MapKit
import Combine

/// Presentation and device location only. Uses the emergency coordinate already
/// supplied by EmergencyStore; never reads or writes Firebase.
@MainActor
final class ParamedicMapRoute: ObservableObject {
    @Published private(set) var paramedicLocation: CLLocationCoordinate2D?
    @Published private(set) var walkingRoute: MKRoute?
    @Published private(set) var initialRegion: MKCoordinateRegion?

    private let locationManager = LocationManager()
    private var destination: CLLocationCoordinate2D?
    private var lastRouteStart: CLLocation?
    private var directions: MKDirections?
    private var requestID: UUID?
    private var hasFramedLocations = false

    func start(to destination: CLLocationCoordinate2D?) {
        stop()
        paramedicLocation = nil
        walkingRoute = nil
        initialRegion = nil
        hasFramedLocations = false
        guard let destination, CLLocationCoordinate2DIsValid(destination) else { return }
        self.destination = destination
        locationManager.onAuthorized = { [weak self] in
            self?.locationManager.startUpdatingLocation()
        }
        locationManager.onDenied = { [weak self] in
            self?.locationManager.stopUpdatingLocation()
            self?.cancelDirections()
            self?.paramedicLocation = nil
            self?.walkingRoute = nil
        }
        locationManager.onLocationReceived = { [weak self] coordinate in
            self?.receive(coordinate)
        }
        locationManager.requestPermission()
    }

    func stop() {
        locationManager.onAuthorized = nil
        locationManager.onDenied = nil
        locationManager.onLocationReceived = nil
        locationManager.stopUpdatingLocation()
        destination = nil
        cancelDirections()
    }

    private func receive(_ coordinate: CLLocationCoordinate2D) {
        guard let destination, CLLocationCoordinate2DIsValid(coordinate) else { return }
        paramedicLocation = coordinate
        // Same first-location framing and minimum span as the companion map.
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
        let start = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let lastRouteStart, start.distance(from: lastRouteStart) < 15 { return }
        lastRouteStart = start
        directions?.cancel()
        let nextID = UUID()
        requestID = nextID
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .walking
        let pending = MKDirections(request: request)
        directions = pending
        pending.calculate { [weak self] response, _ in
            DispatchQueue.main.async {
                guard let self, self.requestID == nextID else { return }
                self.directions = nil
                self.walkingRoute = response?.routes.first
                if self.walkingRoute == nil { self.lastRouteStart = nil }
            }
        }
    }

    private func cancelDirections() {
        requestID = nil
        directions?.cancel()
        directions = nil
        lastRouteStart = nil
    }
}

/// Reuses the team's marker without modifying the companion map file.
struct ParamedicRouteOverlay: MapContent {
    @ObservedObject var route: ParamedicMapRoute

    var body: some MapContent {
        if let coordinate = route.paramedicLocation {
            Annotation("Paramedic location", coordinate: coordinate) {
                CompanionCurrentLocationMarker()
            }
        }
        if let walkingRoute = route.walkingRoute {
            MapPolyline(walkingRoute.polyline)
                .stroke(.red, lineWidth: 4)
        }
    }
}
