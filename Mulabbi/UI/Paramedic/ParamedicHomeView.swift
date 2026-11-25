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
    @State private var selectedEmergency: EmergencySelection?
    @StateObject private var mapRoute = ParamedicMapRoute()
    @StateObject private var profileStore = ParamedicSettingsStore()
    private static let allowedAreaValidator = AllowedAreaValidator()
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

    private var allowedParamedicLocation: CLLocationCoordinate2D? {
        // نتأكد ان موقع المسعف متوفر وانه داخل النطاق المسموح
        guard let coordinate = mapRoute.paramedicLocation,
              Self.allowedAreaValidator.isLocationAllowed(coordinate) else { return nil }
        return coordinate
    }

    private var visibleEmergencyLocations: [EmergencyLocation] {
        // اذا كان موقع المسعف خارج النطاق المسموح ما نعرض له بلاغات
        guard let coordinate = allowedParamedicLocation else { return [] }
        let currentLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return emergencyStore.emergencyLocations
            .filter {
                // نعرض بس البلاغات اللي داخل النطاق ولسى ما انقبلت
                // نستبعد البلاغ النشط عشان يختفي من الخريطة اول ما يقبله المسعف
                ($0.paramedicUsername ?? "").isEmpty
                    && $0.id != emergencyStore.activeEmergencyID
                    && Self.allowedAreaValidator.isLocationAllowed($0.coordinate)
            }
        // نحسب كم يبعد كل بلاغ عن المسعف
            .map { location in
                let destination = CLLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                return (location: location, distance: currentLocation.distance(from: destination))
            }
        // نرتب البلاغات من الاقرب للأبعد
            .sorted {
                if $0.distance == $1.distance {
                    return ($0.location.alertID ?? $0.location.id.uuidString)
                        < ($1.location.alertID ?? $1.location.id.uuidString)
                }
                return $0.distance < $1.distance
            }
        // ناخذ اقرب خمسة من القائمة واذا الموجود اقل نعرض المتاح
            .prefix(5)
            .map { $0.location }
    }

    private struct ReportMapMarker {
        let anchor: EmergencyLocation
        var reports: [EmergencyLocation]
    }

    private struct ReportPinPlacement: Identifiable {
        let report: EmergencyLocation
        let coordinate: CLLocationCoordinate2D

        var id: UUID { report.id }
    }

    private var reportPinPlacements: [ReportPinPlacement] {
        
        let groupingDistance: CLLocationDistance = 50
        let reports = visibleEmergencyLocations.sorted {
            $0.id.uuidString < $1.id.uuidString
        }

        var markers: [ReportMapMarker] = []
        for report in reports {
            let reportPoint = MKMapPoint(report.coordinate)
            if let index = markers.firstIndex(where: {
                reportPoint.distance(to: MKMapPoint($0.anchor.coordinate)) <= groupingDistance
            }) {
                markers[index].reports.append(report)
            } else {
                markers.append(ReportMapMarker(anchor: report, reports: [report]))
            }
        }
        return markers.flatMap { marker -> [ReportPinPlacement] in
            guard marker.reports.count > 1 else {
                return [ReportPinPlacement(report: marker.anchor, coordinate: marker.anchor.coordinate)]
            }

            
            let anchor = MKMapPoint(marker.anchor.coordinate)
            let spacing = 540 * MKMapPointsPerMeterAtLatitude(marker.anchor.coordinate.latitude)
            let rowCount = (marker.reports.count + 1) / 2

            return marker.reports.enumerated().map { index, report in
                let row = index / 2
                let column = index % 2
                let x = (Double(column) - 0.5) * spacing
                let y = (Double(row) - Double(rowCount - 1) / 2) * spacing
                let coordinate = MKMapPoint(x: anchor.x + x, y: anchor.y + y).coordinate
                return ReportPinPlacement(report: report, coordinate: coordinate)
            }
        }
    }

    private func reportPin(for report: EmergencyLocation) -> some View {
        Button {
            selectedEmergency = EmergencySelection(location: report)
        } label: {
            CompanionLocationMarker()
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private struct EmergencySelection: Hashable {
        let location: EmergencyLocation

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.location.id == rhs.location.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(location.id)
        }
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
            
            
            
            Map(position: $cameraPosition) {
                ForEach(reportPinPlacements) { pin in
                    Annotation("", coordinate: pin.coordinate, anchor: .center) {
                        reportPin(for: pin.report)
                    }
                }
                ParamedicRouteOverlay(route: mapRoute, showsWalkingRoute: allowedParamedicLocation != nil)
            }
            .mapStyle(.standard)
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
        .navigationDestination(item: $selectedEmergency) { selection in
            emergencyDetails(for: selection.location)
        }
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
