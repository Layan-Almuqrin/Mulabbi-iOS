import SwiftUI
import MapKit
import CoreLocation

struct ParamedicHomeView: View {
    
    
    
    @ObservedObject var emergencyStore: EmergencyStore
    
    
    
    
    @Binding var homePath: NavigationPath
    
    
    
    
    @Binding var homeNavigationID: UUID
    
    
   
    
    init(
        emergencyStore: EmergencyStore,
        homePath: Binding<NavigationPath> = .constant(NavigationPath()),
        homeNavigationID: Binding<UUID> = .constant(UUID())
    ) {
        
        self._emergencyStore = ObservedObject(
            wrappedValue: emergencyStore
        )
        
        self._homePath = homePath
        
        self._homeNavigationID = homeNavigationID
    }
    
    
    
    
    @State private var isMapVisible = false
    @State private var visibleMapRect: MKMapRect?
    @StateObject private var mapRoute = ParamedicMapRoute()
    @StateObject private var profileStore = ParamedicSettingsStore()
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: 21.4225,
                longitude: 39.8262
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.018,
                longitudeDelta: 0.018
            )
        )
    )
    
    
    private var activeEmergencyCoordinate: CLLocationCoordinate2D? {
        emergencyStore.emergencyLocations.first {
            $0.id == emergencyStore.activeEmergencyID
        }?.coordinate
    }

    private var activeRouteKey: String? {
        guard let coordinate = activeEmergencyCoordinate else { return nil }
        return "\(emergencyStore.activeEmergencyID?.uuidString ?? ""):\(coordinate.latitude):\(coordinate.longitude)"
    }

    private var visibleEmergencyLocations: [EmergencyLocation] {
        let assigned = emergencyStore.emergencyLocations.filter { location in
            if let owner = location.paramedicUsername, !owner.isEmpty {
                return ParamedicEmergencySchema.sameUsername(owner, emergencyStore.currentParamedicUsername)
            }
            return location.id == emergencyStore.activeEmergencyID
        }
        guard let coordinate = mapRoute.paramedicLocation else { return assigned }
        let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        let nearest = emergencyStore.emergencyLocations
            .filter {
                ($0.paramedicUsername ?? "").isEmpty && $0.id != emergencyStore.activeEmergencyID
            }
            .map { location in
                let destination = CLLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                return (location: location, distance: currentLocation.distance(from: destination))
            }
            .sorted {
                if $0.distance == $1.distance {
                    return ($0.location.alertID ?? $0.location.id.uuidString)
                        < ($1.location.alertID ?? $1.location.id.uuidString)
                }
                return $0.distance < $1.distance
            }
            .prefix(5)
            .map { $0.location }
        return assigned + nearest
    }

    private struct EmergencyPin: Identifiable {
        let location: EmergencyLocation
        let point: CGPoint
        let displayCoordinate: CLLocationCoordinate2D

        var id: UUID { location.id }
    }

    private func emergencyPins(in size: CGSize) -> [EmergencyPin] {
        let region = cameraPosition.region
        let center = region?.center ?? CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262)
        let span = region?.span ?? MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        let topLeft = MKMapPoint(CLLocationCoordinate2D(
            latitude: center.latitude + span.latitudeDelta / 2,
            longitude: center.longitude - span.longitudeDelta / 2
        ))
        let bottomRight = MKMapPoint(CLLocationCoordinate2D(
            latitude: center.latitude - span.latitudeDelta / 2,
            longitude: center.longitude + span.longitudeDelta / 2
        ))
        let rect = visibleMapRect ?? MKMapRect(
            x: topLeft.x, y: topLeft.y,
            width: abs(bottomRight.x - topLeft.x), height: abs(bottomRight.y - topLeft.y)
        )
        let xScale = max(Double(size.width), 1) / max(rect.width, 1)
        let yScale = max(Double(size.height), 1) / max(rect.height, 1)

        let markerDiameter: CGFloat = 146
        let screen = CGRect(
            x: -size.width / 2, y: -size.height / 2,
            width: size.width, height: size.height
        ).insetBy(dx: markerDiameter / 2, dy: markerDiameter / 2)
        var pins: [EmergencyPin] = []
        for location in visibleEmergencyLocations {
            let coordinate = MKMapPoint(location.coordinate)
            let origin = CGPoint(
                x: (coordinate.x - rect.midX) * xScale,
                y: (coordinate.y - rect.midY) * yScale
            )
            let occupied = pins.map(\.point)

            func isClear(_ point: CGPoint) -> Bool {
                occupied.allSatisfy { hypot(point.x - $0.x, point.y - $0.y) >= markerDiameter }
            }

            var position = origin
            if !isClear(origin) {
                var nearestClearPoint: CGPoint?
                for ring in 1...(occupied.count + 1) {
                    let radius = CGFloat(ring) * markerDiameter
                    let candidates = (0..<8).map { direction in
                        let angle = CGFloat(direction) * .pi / 4
                        return CGPoint(
                            x: origin.x + cos(angle) * radius,
                            y: origin.y + sin(angle) * radius
                        )
                    }
                    let clearPoints = candidates.filter(isClear)
                    if nearestClearPoint == nil { nearestClearPoint = clearPoints.first }
                    if let onScreen = clearPoints.first(where: screen.contains) {
                        nearestClearPoint = onScreen
                        break
                    }
                }
                if let nearestClearPoint {
                    position = nearestClearPoint
                }
            }

            let isDisplaced = position != origin
            let displayCoordinate = isDisplaced ? MKMapPoint(
                x: Double(position.x) / xScale + rect.midX,
                y: Double(position.y) / yScale + rect.midY
            ).coordinate : location.coordinate
            pins.append(EmergencyPin(
                location: location,
                point: position,
                displayCoordinate: displayCoordinate
            ))
        }
        return pins
    }

    @ViewBuilder
    private func emergencyDetails(for location: EmergencyLocation) -> some View {
        switch location.type {
        case .patient(let patient):
            EmergencyDetailsView(
                patient: patient,
                emergencyID: location.id,
                emergencyStore: emergencyStore,
                emergencyLocation: location.coordinate,
                homePath: $homePath,
                homeNavigationID: $homeNavigationID
            )
        case .companion(let report):
            CompanionEmergencyDetailsView(
                report: report,
                emergencyID: location.id,
                emergencyStore: emergencyStore,
                emergencyLocation: location.coordinate,
                homePath: $homePath,
                homeNavigationID: $homeNavigationID
            )
        }
    }

    var body: some View {
        
        ZStack {
            
            
            
            GeometryReader { geometry in
                Map(position: $cameraPosition) {
                    ForEach(emergencyPins(in: geometry.size)) { pin in
                        Annotation("", coordinate: pin.displayCoordinate, anchor: .center) {
                            NavigationLink {
                                emergencyDetails(for: pin.location)
                            } label: {
                                CompanionLocationMarker()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    ParamedicRouteOverlay(route: mapRoute)
                }
                .mapStyle(.standard)
                .onMapCameraChange(frequency: .onEnd) { context in
                    visibleMapRect = context.rect
                }
            }
            .onAppear {
                isMapVisible = true
                mapRoute.start(to: activeEmergencyCoordinate)
            }
            .onDisappear {
                isMapVisible = false
                mapRoute.stop()
            }
            .onChange(of: activeRouteKey) { _, _ in
                guard isMapVisible else { return }
                mapRoute.updateDestination(activeEmergencyCoordinate)
            }
            .onReceive(mapRoute.$initialRegion) { region in
                if let region { cameraPosition = .region(region) }
            }
            .ignoresSafeArea()
            
            
            
            
            VStack {
                
                ZStack {
                    
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 34,
                        bottomTrailingRadius: 34,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.15),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    
                    
                    HStack(spacing: 12) {
                        
                        Image(systemName: "person.crop.circle.fill")
                            .font(
                                .system(size: 40)
                            )
                            .foregroundStyle(
                                Color.gray.opacity(0.78)
                            )
                        
                        
                        Text(profileStore.profile.firstName.isEmpty ? "Welcome!" : "Welcome \(profileStore.profile.firstName) !")
                            .font(
                                .system(
                                    size: 23,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.black)
                        
                        
                        Spacer()
                    }
                    .padding(.horizontal, 44)
                    .padding(.top, 38)
                }
                .frame(height: 122)
                
                
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        .task {
            await emergencyStore.loadEmergencies()
            await profileStore.fetch()
        }
    }
}




struct EmergencyLocation: Identifiable {
    
    let id: UUID
    
    let alertID: String?
    let paramedicUsername: String?
    
    let coordinate: CLLocationCoordinate2D
    
    let type: EmergencyType
    
    
    init(
        id: UUID = UUID(),
        alertID: String? = nil,
        paramedicUsername: String? = nil,
        coordinate: CLLocationCoordinate2D,
        type: EmergencyType
    ) {
        
        self.id = id
        self.alertID = alertID
        self.paramedicUsername = paramedicUsername
        self.coordinate = coordinate
        self.type = type
    }
}




enum EmergencyType {
    
    case patient(EmergencyPatient)
    
    case companion(CompanionEmergencyReport)
}




struct LocationPin: View {
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            PinShape()
                .fill(Color.mulabbiMaroon)
            
            
            Circle()
                .fill(Color.white)
                .frame(
                    width: 12,
                    height: 12
                )
                .padding(.top, 8)
        }
    }
}




struct PinShape: Shape {
    
    func path(in rect: CGRect) -> Path {
        
        let width = rect.width
        let height = rect.height
        
        var path = Path()
        
        
        path.move(
            to: CGPoint(
                x: width * 0.50,
                y: height
            )
        )
        
        
        path.addCurve(
            to: CGPoint(
                x: width * 0.12,
                y: height * 0.36
            ),
            control1: CGPoint(
                x: width * 0.43,
                y: height * 0.82
            ),
            control2: CGPoint(
                x: width * 0.12,
                y: height * 0.62
            )
        )
        
        
        path.addCurve(
            to: CGPoint(
                x: width * 0.50,
                y: 0
            ),
            control1: CGPoint(
                x: width * 0.12,
                y: height * 0.15
            ),
            control2: CGPoint(
                x: width * 0.28,
                y: 0
            )
        )
        
        
        path.addCurve(
            to: CGPoint(
                x: width * 0.88,
                y: height * 0.36
            ),
            control1: CGPoint(
                x: width * 0.72,
                y: 0
            ),
            control2: CGPoint(
                x: width * 0.88,
                y: height * 0.15
            )
        )
        
        
        path.addCurve(
            to: CGPoint(
                x: width * 0.50,
                y: height
            ),
            control1: CGPoint(
                x: width * 0.88,
                y: height * 0.62
            ),
            control2: CGPoint(
                x: width * 0.57,
                y: height * 0.82
            )
        )
        
        
        path.closeSubpath()
        
        return path
    }
}




#Preview {
    
    NavigationStack {
        
        ParamedicHomeView(
            emergencyStore: EmergencyStore()
        )
    }
}
