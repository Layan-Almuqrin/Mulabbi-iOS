import SwiftUI
import MapKit

struct CaseHistoryDetailsView: View {
    
    
    
    let completedCase: CompletedEmergency
    
    
    
    
    let onClose: () -> Void
    
    
    
    
    private var patientName: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.name
        case .companion(let report):
            return report.reporterName
        }
    }
    
    
    private var username: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.username
        case .companion(let report):
            return report.reporterUsername
        }
    }
    
    
    private var phoneNumber: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.phoneNumber
        case .companion(let report):
            return report.reporterPhoneNumber
        }
    }
    
    
    private var age: String {
        switch completedCase.type {
        case .patient(let patient):
            return "\(patient.age)"
        case .companion:
            return "—"
        }
    }
    
    
    private var nationality: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.nationality
        case .companion:
            return "—"
        }
    }
    
    
    private var language: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.language
        case .companion:
            return "—"
        }
    }
    
    
    private var gender: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.gender
        case .companion:
            return "—"
        }
    }
    
    
    private var bloodType: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.bloodType
        case .companion:
            return "—"
        }
    }
    
    
    private var chronicDiseases: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.chronicDiseases
        case .companion:
            return "—"
        }
    }
    
    
    private var allergies: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.allergies
        case .companion:
            return "—"
        }
    }
    
    
    private var medications: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.medications
        case .companion:
            return "—"
        }
    }
    
    
    private var otherInfo: String {
        switch completedCase.type {
        case .patient(let patient):
            return patient.otherInfo
        case .companion(let report):
            return report.situationDescription
        }
    }
    
    
    var body: some View {
        
        GeometryReader { geo in
            
            ZStack {
                
              
                
                
                Color.black
                    .opacity(0.20)
                    .ignoresSafeArea()
                
                
             
                
                
                VStack(spacing: 0) {
                    
                   
                   
                    
                    ZStack(alignment: .topLeading) {
                        
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .fill(
                            Color(
                                red: 0.90,
                                green: 0.90,
                                blue: 0.88
                            )
                            .opacity(0.90)
                        )
                        
                        
                        Button {
                            
                            onClose()
                            
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
                        .padding(.leading, 15)
                        .padding(.top, 10)
                    }
                    .frame(height: 56)
                    
                    
                       
                    
                    ScrollView(
                        .vertical,
                        showsIndicators: false
                    ) {
                        
                        VStack(
                            alignment: .leading,
                            spacing: 0
                        ) {
                            
                            Text("Age : \(age)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 13)
                            
                            
                            Text("Nationality : \(nationality)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 13)
                            
                            
                            Text("Language : \(language)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 18)
                            
                            
                            Text("Medical Record :")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.black)
                                .padding(.bottom, 13)
                            
                            
                            Text("Gender : \(gender)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 13)
                            
                            
                            Text("Blood type : \(bloodType)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 13)
                            
                            
                            Text("Chronic diseases : \(chronicDiseases)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 13)
                            
                            
                            Text("Allergies: \(allergies)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 13)
                            
                            
                            Text("Medications : \(medications)")
                                .caseHistoryDetailText()
                                .padding(.bottom, 13)
                            
                            
                            Text("Other info : \(otherInfo)")
                                .caseHistoryDetailText()
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                                .padding(.bottom, 14)
                            
                            
                            Text("Case Description:")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.black)
                                .padding(.bottom, 8)
                            
                            
                            Text(completedCase.description)
                                .font(
                                    .system(
                                        size: 16.5,
                                        weight: .semibold
                                    )
                                )
                                .foregroundStyle(.black)
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )
                        }
                        .padding(.horizontal, 14)
                        .padding(.top, 14)
                        .padding(.bottom, 16)
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: 610
                    )
                    .background(
                        
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                        .fill(
                            Color(
                                red: 0.96,
                                green: 0.96,
                                blue: 0.94
                            )
                        )
                        .overlay(
                            
                            RoundedRectangle(
                                cornerRadius: 12,
                                style: .continuous
                            )
                            .stroke(
                                Color.black.opacity(0.22),
                                lineWidth: 1
                            )
                        )
                        .shadow(
                            color: .black.opacity(0.15),
                            radius: 3,
                            x: 0,
                            y: 2
                        )
                    )
                    .padding(.horizontal, 13)
                    .padding(.bottom, 14)
                }
                .background(
                    
                    RoundedRectangle(
                        cornerRadius: 18,
                        style: .continuous
                    )
                    .fill(
                        Color(
                            red: 0.90,
                            green: 0.90,
                            blue: 0.88
                        )
                        .opacity(0.92)
                    )
                    .overlay(
                        
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .stroke(
                            Color.black.opacity(0.23),
                            lineWidth: 1
                        )
                    )
                )
                .frame(
                    width: geo.size.width - 26
                )
                .zIndex(3)
            }
        }
        .toolbar(
            .hidden,
            for: .navigationBar
        )
        .toolbar(
            .hidden,
            for: .tabBar
        )
    }
}





extension Text {
    
    func caseHistoryDetailText() -> some View {
        
        self
            .font(
                .system(
                    size: 17,
                    weight: .semibold
                )
            )
            .foregroundStyle(.black)
    }
}





#Preview {
    
    let sample = CompletedEmergency(
        emergencyID: UUID(),
        type: .patient(
            EmergencyPatient.sample
        ),
        coordinate: CLLocationCoordinate2D(
            latitude: 21.4277,
            longitude: 39.8208
        ),
        description:
        """
        The pilgrim had a minor leg injury after falling. I assessed the injury, cleaned and disinfected the wound, and applied a bandage.
        """,
        completedAt: Date()
    )
    
    CaseHistoryDetailsView(
        completedCase: sample,
        onClose: {}
    )
}
