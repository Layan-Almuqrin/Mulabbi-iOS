import SwiftUI
import MapKit



struct EmergencyPatient: Identifiable, Codable {
    
    var id: String
    
    var name: String
    var username: String
    var phoneNumber: String
    var age: Int
    var nationality: String
    var language: String
    
    var gender: String
    var bloodType: String
    var chronicDiseases: String
    var allergies: String
    var medications: String
    var otherInfo: String
}




struct EmergencyDetailsView: View {
    
    
    
    let patient: EmergencyPatient
    
    let emergencyID: UUID
    
    @ObservedObject var emergencyStore: EmergencyStore
    
    let emergencyLocation: CLLocationCoordinate2D
    
    
    
    @Binding var homePath: NavigationPath
    
    @Binding var homeNavigationID: UUID
    
    
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection
    
    @State private var goToActiveEmergency = false
    
    
    
    init(
        patient: EmergencyPatient,
        emergencyID: UUID,
        emergencyStore: EmergencyStore,
        emergencyLocation: CLLocationCoordinate2D,
        homePath: Binding<NavigationPath> = .constant(NavigationPath()),
        homeNavigationID: Binding<UUID> = .constant(UUID())
    ) {
        
        self.patient = patient
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
                                size: 29,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                        .shadow(
                            color: .black.opacity(0.30),
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
                    
                    
                    Text(patient.name)
                        .font(
                            .system(
                                size: 28,
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
                            
                            
                            HStack {
                                
                                if layoutDirection == .rightToLeft {
                                    Spacer()
                                }
                                
                                Button {
                                    
                                    dismiss()
                                    
                                } label: {
                                    
                                    Image(systemName: "xmark.circle")
                                        .font(
                                            .system(
                                                size: 26,
                                                weight: .medium
                                            )
                                        )
                                        .foregroundStyle(.black)
                                }
                                
                                if layoutDirection == .leftToRight {
                                    Spacer()
                                }
                            }
                            .environment(\.layoutDirection, .leftToRight)
                            .padding(.bottom, 10)
                            
                            
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Phone Number"),
                                value: patient.phoneNumber
                            )
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Age"),
                                value: "\(patient.age)"
                            )
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Nationality"),
                                value: patient.nationality
                            )
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Language"),
                                value: patient.language
                            )
                            
                            
                            
                            LocalizedSectionTitle(
                                title: LocalizedStringKey("Medical Record")
                            )
                            .padding(.top, 10)
                            .padding(.bottom, 8)
                            
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Gender"),
                                value: patient.gender
                            )
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Blood type"),
                                value: patient.bloodType
                            )
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Chronic diseases"),
                                value: patient.chronicDiseases,
                                allowWrapping: true
                            )
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Allergies"),
                                value: patient.allergies
                            )
                            
                            PatientInfoRow(
                                title: LocalizedStringKey("Medications"),
                                value: patient.medications
                            )
                            
                            
                            
                            HStack(spacing: 0) {
                                
                                if layoutDirection == .rightToLeft {
                                    Spacer(minLength: 0)
                                }
                                
                                VStack(
                                    alignment: layoutDirection == .rightToLeft
                                        ? .trailing
                                        : .leading,
                                    spacing: 4
                                ) {
                                    
                                    HStack(spacing: 2) {
                                        
                                        if layoutDirection == .rightToLeft {
                                            Text(":")
                                            
                                            Text("Other info")
                                        } else {
                                            Text("Other info")
                                            
                                            Text(":")
                                        }
                                    }
                                    .environment(\.layoutDirection, .leftToRight)
                                    .font(
                                        .system(
                                            size: 18,
                                            weight: .semibold
                                        )
                                    )
                                    
                                    
                                    Text(patient.otherInfo)
                                        .font(
                                            .system(
                                                size: 18,
                                                weight: .semibold
                                            )
                                        )
                                        .multilineTextAlignment(
                                            layoutDirection == .rightToLeft
                                                ? .trailing
                                                : .leading
                                        )
                                        .fixedSize(
                                            horizontal: false,
                                            vertical: true
                                        )
                                }
                                
                                if layoutDirection == .leftToRight {
                                    Spacer(minLength: 0)
                                }
                            }
                            .environment(\.layoutDirection, .leftToRight)
                            .foregroundStyle(.black)
                            .padding(.top, 6)
                            .padding(.bottom, 35)
                        }
                        .padding(.horizontal, 17)
                        .padding(.top, 12)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: 500
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
                                    size: 28,
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




struct PatientInfoRow: View {
    
    let title: LocalizedStringKey
    let value: String
    
    var allowWrapping: Bool = false
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    
    var body: some View {
        
        HStack(
            alignment: .firstTextBaseline,
            spacing: 0
        ) {
            
            if layoutDirection == .rightToLeft {
                
                Spacer(minLength: 0)
                
                
                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 4
                ) {
                    
                    Text(value)
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                        .fixedSize(
                            horizontal: false,
                            vertical: allowWrapping
                        )
                    
                    Text(":")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                    
                    Text(title)
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                }
                
            } else {
                
                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 4
                ) {
                    
                    Text(title)
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                    
                    Text(":")
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                    
                    Text(value)
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                        .fixedSize(
                            horizontal: false,
                            vertical: allowWrapping
                        )
                }
                
                
                Spacer(minLength: 0)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 9)
    }
}




struct LocalizedSectionTitle: View {
    
    let title: LocalizedStringKey
    
    var fontSize: CGFloat = 24
    var fontWeight: Font.Weight = .bold
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    
    var body: some View {
        
        HStack(spacing: 0) {
            
            if layoutDirection == .rightToLeft {
                
                Spacer(minLength: 0)
                
                Text(":")
                
                Text(title)
                
            } else {
                
                Text(title)
                
                Text(":")
                
                Spacer(minLength: 0)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .font(
            .system(
                size: fontSize,
                weight: fontWeight
            )
        )
        .foregroundStyle(.black)
        .frame(maxWidth: .infinity)
    }
}




extension EmergencyPatient {
    
    static let sample = EmergencyPatient(
        id: "patient_001",
        name: "Shatha Alessa",
        username: "Shatha77m",
        phoneNumber: "0556786799",
        age: 20,
        nationality: "British",
        language: "English",
        gender: "Female",
        bloodType: "O+",
        chronicDiseases: "Diabetes (Type2)",
        allergies: "Penicillin",
        medications: "Metformin",
        otherInfo: "I carry insulin with me and may need it in emergencies"
    )
}




#Preview {
    
    NavigationStack {
        
        EmergencyDetailsView(
            patient: .sample,
            emergencyID: UUID(),
            emergencyStore: EmergencyStore(),
            emergencyLocation: CLLocationCoordinate2D(
                latitude: 21.4277,
                longitude: 39.8208
            )
        )
    }
}
