import SwiftUI
import MapKit

struct ActiveEmergencyView: View {
    
    
    
    let emergencyID: UUID
    
    @ObservedObject var emergencyStore: EmergencyStore
    
    let emergencyLocation: CLLocationCoordinate2D
    
    
   
    
    @Binding var homePath: NavigationPath
    
    @Binding var homeNavigationID: UUID
    
    
   
    
    @State private var goToEmergencyDescription = false
    
    
    
    
    @State private var cameraPosition: MapCameraPosition
    
    
   
    
    init(
        emergencyID: UUID = UUID(),
        emergencyStore: EmergencyStore = EmergencyStore(),
        emergencyLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(
            latitude: 21.4250,
            longitude: 39.8300
        ),
        homePath: Binding<NavigationPath> = .constant(NavigationPath()),
        homeNavigationID: Binding<UUID> = .constant(UUID())
    ) {
        
        self.emergencyID = emergencyID
        
        self._emergencyStore = ObservedObject(
            wrappedValue: emergencyStore
        )
        
        self.emergencyLocation = emergencyLocation
        
        self._homePath = homePath
        
        self._homeNavigationID = homeNavigationID
        
        
        self._cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: 21.4225,
                        longitude: 39.8262
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.022,
                        longitudeDelta: 0.022
                    )
                )
            )
        )
    }
    
    
    var body: some View {
        
        ZStack {
            
            
            
            Map(position: $cameraPosition) {
                
                Annotation(
                    "",
                    coordinate: emergencyLocation,
                    anchor: .center
                ) {
                    
                    ZStack {
                        
                        Circle()
                            .fill(
                                Color.red.opacity(0.23)
                            )
                            .frame(
                                width: 135,
                                height: 135
                            )
                        
                        
                        LocationPin()
                            .frame(
                                width: 35,
                                height: 44
                            )
                    }
                }
            }
            .mapStyle(.standard)
            .ignoresSafeArea()
            
            
           
            
            VStack(spacing: 0) {
                
               
                
                ZStack {
                    
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 34,
                        bottomTrailingRadius: 34,
                        topTrailingRadius: 0,
                        style: .continuous
                    )
                    .fill(Color.mulabbiMaroon)
                    
                    
                    Text("Active Emergency")
                        .font(
                            .system(
                                size: 30,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.25),
                            radius: 2,
                            x: 1,
                            y: 2
                        )
                        .padding(.top, 38)
                }
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
                
                
                Spacer()
                
                
                
                
                Button {
                    
                    goToEmergencyDescription = true
                    
                } label: {
                    
                    Text("Complete")
                        .font(
                            .system(
                                size: 26,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 50)
                        .background(
                            
                            Capsule()
                                .fill(Color.mulabbiMaroon)
                        )
                }
                .padding(.horizontal, 44)
                .padding(.bottom, 22)
            }
        }
        
        
        
        
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        
        
        
        
        .navigationDestination(
            isPresented: $goToEmergencyDescription
        ) {
            
            EmergencyDescriptionView(
                emergencyID: emergencyID,
                emergencyStore: emergencyStore,
                emergencyLocation: emergencyLocation,
                homePath: $homePath,
                homeNavigationID: $homeNavigationID
            )
        }
    }
}




#Preview {
    
    NavigationStack {
        
        ActiveEmergencyView(
            emergencyID: UUID(),
            emergencyStore: EmergencyStore(),
            emergencyLocation: CLLocationCoordinate2D(
                latitude: 21.4277,
                longitude: 39.8208
            )
        )
    }
}
