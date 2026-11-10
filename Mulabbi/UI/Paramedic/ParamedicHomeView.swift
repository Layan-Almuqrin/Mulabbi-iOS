import SwiftUI
import MapKit

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

    var body: some View {
        
        ZStack {
            
            
            
            Map(position: $cameraPosition) {
                
                ForEach(emergencyStore.emergencyLocations) { location in
                    
                    Annotation(
                        "",
                        coordinate: location.coordinate,
                        anchor: .center
                    ) {
                        
                        NavigationLink {
                            
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
                            
                        } label: {
                            
                            CompanionLocationMarker()
                        }
                        .buttonStyle(.plain)
                    }
                }
                ParamedicRouteOverlay(route: mapRoute)
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
                mapRoute.start(to: activeEmergencyCoordinate)
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
                        
                        
                        Text("Welcome \(profileStore.profile.firstName.isEmpty ? emergencyStore.currentParamedicUsername : profileStore.profile.firstName) !")
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
    
    let coordinate: CLLocationCoordinate2D
    
    let type: EmergencyType
    
    
    init(
        id: UUID = UUID(),
        alertID: String? = nil,
        coordinate: CLLocationCoordinate2D,
        type: EmergencyType
    ) {
        
        self.id = id
        self.alertID = alertID
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
