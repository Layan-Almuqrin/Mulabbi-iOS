import SwiftUI
import MapKit



struct CompanionEmergencyReport: Identifiable, Codable {
    
    var id: String
    
    var reporterName: String
    var reporterUsername: String
    var reporterPhoneNumber: String
    var situationDescription: String
}




struct CompanionEmergencyDetailsView: View {
    
  
    
    let report: CompanionEmergencyReport
    
    let emergencyID: UUID
    
    @ObservedObject var emergencyStore: EmergencyStore
    
    let emergencyLocation: CLLocationCoordinate2D
    
    
   
    
    
    @Binding var homePath: NavigationPath
    
    @Binding var homeNavigationID: UUID
    
    
   
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var goToActiveEmergency = false
    
    
   
    
    init(
        report: CompanionEmergencyReport,
        emergencyID: UUID = UUID(),
        emergencyStore: EmergencyStore = EmergencyStore(),
        emergencyLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(
            latitude: 21.4267,
            longitude: 39.8320
        ),
        homePath: Binding<NavigationPath> = .constant(NavigationPath()),
        homeNavigationID: Binding<UUID> = .constant(UUID())
    ) {
        
        self.report = report
        self.emergencyID = emergencyID
        
        self._emergencyStore = ObservedObject(
            wrappedValue: emergencyStore
        )
        
        self.emergencyLocation = emergencyLocation
        
        self._homePath = homePath
        
        self._homeNavigationID = homeNavigationID
    }
    
    
    var body: some View {
        
        ZStack {
            
            Color.white
                .ignoresSafeArea()
            
            
            VStack(spacing: 0) {
                
                
                
                ZStack {
                    
                    Color.mulabbiMaroon
                    
                    
                    Text("Emergency Details")
                        .font(
                            .system(
                                size: 31,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.35),
                            radius: 2,
                            x: 1,
                            y: 2
                        )
                        .padding(.top, 42)
                        .padding(.bottom, 12)
                }
                .frame(height: 120)
                .ignoresSafeArea(edges: .top)
                
                
              
                
                VStack(spacing: 0) {
                    
                    
                    
                    Text(report.reporterName)
                        .font(
                            .system(
                                size: 30,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.top, 0)
                        .padding(.bottom, 8)
                    
                    
                  
                    
                    ScrollView(
                        .vertical,
                        showsIndicators: false
                    ) {
                        
                        VStack(
                            alignment: .leading,
                            spacing: 0
                        ) {
                            
                            
                            
                            Button {
                                
                                dismiss()
                                
                            } label: {
                                
                                Image(systemName: "xmark.circle")
                                    .font(
                                        .system(
                                            size: 28,
                                            weight: .medium
                                        )
                                    )
                                    .foregroundStyle(.black)
                            }
                            .padding(.bottom, 13)
                            
                            
                           
                            
                            HStack(
                                alignment: .firstTextBaseline,
                                spacing: 4
                            ) {
                                
                                Text("Phone Number :")
                                    .font(
                                        .system(
                                            size: 20,
                                            weight: .semibold
                                        )
                                    )
                                
                                
                                Text(report.reporterPhoneNumber)
                                    .font(
                                        .system(
                                            size: 20,
                                            weight: .semibold
                                        )
                                    )
                                
                                
                                Spacer(minLength: 0)
                            }
                            .foregroundStyle(.black)
                            .padding(.bottom, 18)
                            
                            
                            
                            
                            Text("Description of the situation :")
                                .font(
                                    .system(
                                        size: 18,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(.black)
                                .padding(.bottom, 5)
                            
                            
                            Text(report.situationDescription)
                                .font(
                                    .system(
                                        size: 18,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(.black)
                                .lineSpacing(1)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                            
                            
                            Spacer(minLength: 8)
                        }
                        .padding(.horizontal, 15)
                        .padding(.top, 12)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .background(
                        
                        RoundedRectangle(
                            cornerRadius: 13,
                            style: .continuous
                        )
                        .fill(
                            Color(
                                red: 0.975,
                                green: 0.975,
                                blue: 0.97
                            )
                        )
                        .overlay(
                            
                            RoundedRectangle(
                                cornerRadius: 13,
                                style: .continuous
                            )
                            .stroke(
                                Color.gray.opacity(0.55),
                                lineWidth: 1.2
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.12),
                            radius: 2,
                            x: 1,
                            y: 2
                        )
                    )
                    .padding(.horizontal, 18)
                    
                    
                    
                    
                    Button {
                        
                        goToActiveEmergency = true
                        
                    } label: {
                        
                        Text("Accept")
                            .font(
                                .system(
                                    size: 31,
                                    weight: .semibold
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
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                }
                .background(Color.white)
                .clipShape(
                    
                    UnevenRoundedRectangle(
                        topLeadingRadius: 48,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 48,
                        style: .continuous
                    )
                )
                .offset(y: -52)
            }
        }
        
        
        
        
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        
        
        
        
        .navigationDestination(
            isPresented: $goToActiveEmergency
        ) {
            
            ActiveEmergencyView(
                emergencyID: emergencyID,
                emergencyStore: emergencyStore,
                emergencyLocation: emergencyLocation,
                homePath: $homePath,
                homeNavigationID: $homeNavigationID
            )
        }
    }
}




extension CompanionEmergencyReport {
    
    static let sample = CompanionEmergencyReport(
        
        id: "report_001",
        
        reporterName: "Shatha Alessa",
        
        reporterUsername: "Shatha77m",
        
        reporterPhoneNumber: "0556786799",
        
        situationDescription:
        """
        I saw a woman sitting on the ground who looked very tired. She was holding her chest and having difficulty breathing. She seemed confused and was unable to stand. Her face looked pale, and she was sweating noticeably. She told me that the chest pain started suddenly a short while ago. She was speaking with difficulty and her voice was weak, and every time she tried to take a breath, she seemed to struggle more. I did not notice any visible injuries, so I reported the situation immediately.
        """
    )
}




#Preview {
    
    NavigationStack {
        
        CompanionEmergencyDetailsView(
            report: .sample
        )
    }
}
