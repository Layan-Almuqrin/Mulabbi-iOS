import SwiftUI
import MapKit

struct EmergencyDescriptionView: View {
    
  
    
    let emergencyID: UUID
    
    @ObservedObject var emergencyStore: EmergencyStore
    
    let emergencyLocation: CLLocationCoordinate2D
    
    
   
    
    @Binding var homePath: NavigationPath
    
    @Binding var homeNavigationID: UUID
    
    
   
    
    @State private var descriptionText: String = ""
    
    
    
    
    @State private var cameraPosition: MapCameraPosition
    
    
   
    
    @Environment(\.dismiss) private var dismiss
    
    
   
    
    init() {
        
        let store = EmergencyStore()
        
        self.emergencyID = UUID()
        
        self._emergencyStore = ObservedObject(
            wrappedValue: store
        )
        
        self.emergencyLocation = CLLocationCoordinate2D(
            latitude: 21.4262,
            longitude: 39.8310
        )
        
        self._homePath = .constant(
            NavigationPath()
        )
        
        self._homeNavigationID = .constant(
            UUID()
        )
        
        _cameraPosition = State(
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
    
    
     
    
    init(
        emergencyLocation: CLLocationCoordinate2D
    ) {
        
        let store = EmergencyStore()
        
        self.emergencyID = UUID()
        
        self._emergencyStore = ObservedObject(
            wrappedValue: store
        )
        
        self.emergencyLocation = emergencyLocation
        
        self._homePath = .constant(
            NavigationPath()
        )
        
        self._homeNavigationID = .constant(
            UUID()
        )
        
        _cameraPosition = State(
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
    
    
    
    init(
        emergencyID: UUID,
        emergencyStore: EmergencyStore,
        emergencyLocation: CLLocationCoordinate2D,
        homePath: Binding<NavigationPath> = .constant(
            NavigationPath()
        ),
        homeNavigationID: Binding<UUID> = .constant(
            UUID()
        )
    ) {
        
        self.emergencyID = emergencyID
        
        self._emergencyStore = ObservedObject(
            wrappedValue: emergencyStore
        )
        
        self.emergencyLocation = emergencyLocation
        
        self._homePath = homePath
        
        self._homeNavigationID = homeNavigationID
        
        _cameraPosition = State(
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
    
   
    
    private var isDescriptionEmpty: Bool {
        
        descriptionText
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            .isEmpty
    }
    
    
    var body: some View {
        
        ZStack {
            
          
            
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
                                    width: 145,
                                    height: 145
                                )
                            
                            
                            EmergencyDescriptionPin()
                                .frame(
                                    width: 38,
                                    height: 48
                                )
                        }
                    }
                }
                .mapStyle(.standard)
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
                            
                            
                            Text("Welcome Fahad !")
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
                
                
               
                
                VStack {
                    
                    Spacer()
                    
                    
                    Button {
                        
                    } label: {
                        
                        Text("Complete")
                            .font(
                                .system(
                                    size: 29,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                Color.white.opacity(0.78)
                            )
                            .frame(
                                maxWidth: .infinity
                            )
                            .frame(height: 58)
                            .background(
                                
                                Capsule()
                                    .fill(
                                        Color.mulabbiMaroon.opacity(0.72)
                                    )
                            )
                    }
                    .disabled(true)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)
                }
            }
            
            
         
            
            Color.black
                .opacity(0.10)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            
            
            
            VStack(spacing: 0) {
                
               
                
                Capsule()
                    .fill(
                        Color.gray.opacity(0.55)
                    )
                    .frame(
                        width: 88,
                        height: 4
                    )
                    .padding(.top, 9)
                
                
                
                
                ZStack(alignment: .top) {
                    
                   
                    
                    HStack {
                        
                        Button {
                            
                            dismiss()
                            
                        } label: {
                            
                            Image(systemName: "xmark.circle")
                                .font(
                                    .system(
                                        size: 27,
                                        weight: .medium
                                    )
                                )
                                .foregroundStyle(.black)
                        }
                        
                        
                        Spacer()
                    }
                    .padding(.leading, 20)
                    .offset(y: -10)
                    
                    
                   
                    
                    Text("Emergency Description")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.90)
                        .padding(.top, 24)
                }
                .frame(height: 78)
                
                
               
                
                HStack {
                    
                    Text("Describe the Situation")
                        .font(.headline)
                        .foregroundStyle(.black)
                    
                    
                    Spacer()
                }
                .padding(.horizontal, 27)
                .padding(.top, 6)
                .padding(.bottom, 9)
                
                
               
                
                ZStack(alignment: .topLeading) {
                    
                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.25))
                    )
                    
                    
                    TextEditor(
                        text: $descriptionText
                    )
                    .font(.body)
                    .foregroundStyle(.black)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(
                        EdgeInsets(
                            top: 9,
                            leading: 9,
                            bottom: 9,
                            trailing: 9
                        )
                    )
                    
                    
                    
                    
                    if isDescriptionEmpty {
                        
                        Text(
                            "Describe the case and the assistance provided..."
                        )
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 16)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                    }
                }
                .frame(height: 395)
                .padding(.horizontal, 25)
                
                
               
                
                Button {
                    
                    guard !isDescriptionEmpty else {
                        return
                    }
                    
                    
                  
                    emergencyStore.completeEmergency(
                        emergencyID: emergencyID,
                        description: descriptionText
                    )
                    
                    
                    print(
                        "Emergency completed:",
                        emergencyID
                    )
                    
                    print(
                        "Case History:",
                        descriptionText
                    )
                    
                    
                    
                    
                    homePath = NavigationPath()
                    
                    homeNavigationID = UUID()
                    
                    
                } label: {
                    
                    Text("Send")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(
                            Color.white.opacity(
                                isDescriptionEmpty
                                ? 0.74
                                : 1.0
                            )
                        )
                        .frame(
                            maxWidth: .infinity
                        )
                        .frame(height: 50)
                        .background(
                            
                            Capsule()
                                .fill(
                                    
                                    isDescriptionEmpty
                                    
                                    ? Color.mulabbiMaroon.opacity(0.45)
                                    : Color.mulabbiMaroon
                                )
                        )
                }
                .disabled(isDescriptionEmpty)
                .padding(.horizontal, 44)
                .padding(.top, 16)
                .padding(.bottom, 18)
            }
            
            
          
            
            .background(
                
                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
                .fill(Color(.systemGroupedBackground))
                .shadow(
                    color: .black.opacity(0.18),
                    radius: 5,
                    x: 0,
                    y: 2
                )
            )
            .padding(.horizontal, 10)
            .offset(y: -31)
            .zIndex(2)
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
    }
}




struct EmergencyDescriptionPin: View {
    
    var body: some View {
        
        ZStack(alignment: .top) {
            
            EmergencyDescriptionPinShape()
                .fill(Color.mulabbiMaroon)
            
            
            Circle()
                .fill(Color.white)
                .frame(
                    width: 13,
                    height: 13
                )
                .padding(.top, 8)
        }
    }
}



struct EmergencyDescriptionPinShape: Shape {
    
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
        
        EmergencyDescriptionView()
    }
}
