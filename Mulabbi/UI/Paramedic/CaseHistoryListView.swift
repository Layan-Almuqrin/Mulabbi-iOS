import SwiftUI

struct CaseHistoryListView: View {
    
    
    
    @ObservedObject var emergencyStore: EmergencyStore
    
    
    
    
    @Environment(\.dismiss) private var dismiss
    let onBack: (() -> Void)?
    
    
    
    
    @State private var selectedCase: CompletedEmergency?
    
    
    
    
    init(
        emergencyStore: EmergencyStore = EmergencyStore(),
        onBack: (() -> Void)? = nil
    ) {
        
        self._emergencyStore = ObservedObject(
            wrappedValue: emergencyStore
        )
        self.onBack = onBack
    }
    
    
    var body: some View {
        
        ZStack {
            
            
            
            Color(
                red: 0.97,
                green: 0.97,
                blue: 0.96
            )
            .ignoresSafeArea()
            
            
            VStack(spacing: 0) {
                
                
                
                SettingsEditorHeader(
                    title: "Case History",
                    onBack: {
                        if let onBack {
                            onBack()
                        } else {
                            dismiss()
                        }
                    }
                )
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 10)
                
                
                
                
                if emergencyStore.completedEmergencies.isEmpty {
                    
                    Spacer()
                    
                    
                    VStack(spacing: 16) {
                        
                        Image(systemName: "clipboard")
                            .font(
                                .system(
                                    size: 74,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                Color.black.opacity(0.78)
                            )
                        
                        
                        Text("No cases found")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                Color.black.opacity(0.82)
                            )
                    }
                    .offset(y: -40)
                    
                    
                    Spacer()
                    
                } else {
                    
                    ScrollView(
                        .vertical,
                        showsIndicators: false
                    ) {
                        
                        VStack(spacing: 14) {
                            
                            ForEach(
                                Array(
                                    emergencyStore
                                        .completedEmergencies
                                        .reversed()
                                )
                            ) { completedCase in
                                
                                CaseHistoryRow(
                                    completedCase: completedCase,
                                    onViewDetails: {
                                        
                                        selectedCase = completedCase
                                    }
                                )
                            }
                        }
                        .padding(.top, 18)
                        .padding(.bottom, 30)
                    }
                }
            }
            
            
            
            
            if let selectedCase {
                
                CaseHistoryDetailsView(
                    completedCase: selectedCase,
                    onClose: {
                        
                        self.selectedCase = nil
                    }
                )
                .zIndex(10)
            }
        }
        
        
    
        
        .animation(
            nil,
            value: selectedCase?.id
        )
        
        
       
        
        .navigationBarBackButtonHidden(true)
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




struct CaseHistoryRow: View {
    
    let completedCase: CompletedEmergency
    
    let onViewDetails: () -> Void
    
    
    
    private var caseName: String {
        
        switch completedCase.type {
            
        case .patient(let patient):
            
            return patient.name
            
            
        case .companion(let report):
            
            return report.reporterName
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
    
    
    
    
    private var username: String {
        
        switch completedCase.type {
            
        case .patient(let patient):
            
            return patient.username
            
            
        case .companion(let report):
            
            return report.reporterUsername
        }
    }
    
    
    var body: some View {
        
        HStack(spacing: 8) {
            
            
            
            ZStack {
                
                Circle()
                    .fill(
                        Color.gray.opacity(0.74)
                    )
                    .frame(
                        width: 46,
                        height: 46
                    )
                
                
                Image(systemName: "person.fill")
                    .font(
                        .system(
                            size: 25,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(.white)
                    .offset(y: 1)
            }
            
            
           
            
            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                
                Text(caseName)
                    .font(
                        .system(
                            size: 22,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                
                Text("Username: \(username)")
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.96)
                    )
                    .lineLimit(1)
                
                
                Text("Phone number: \(phoneNumber)")
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.96)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
                    .allowsTightening(true)
            }
            .layoutPriority(1)
            
            
            Spacer(minLength: 2)
            
            
           
            
            Button {
                
                onViewDetails()
                
            } label: {
                
                Text("View Details")
                    .font(
                        .system(
                            size: 12.5,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(Color.mulabbiMaroon)
                    .frame(
                        width: 94,
                        height: 38
                    )
                    .background(
                        
                        RoundedRectangle(
                            cornerRadius: 20,
                            style: .continuous
                        )
                        .fill(
                            Color.white.opacity(0.94)
                        )
                    )
            }
            .buttonStyle(.plain)
            .fixedSize()
        }
        .padding(.horizontal, 14)
        .frame(height: 92)
        .background(
            
            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(
                
                LinearGradient(
                    colors: [
                        Color.mulabbiMaroon,
                        Color.mulabbiCardRose
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .shadow(
                color: .black.opacity(0.18),
                radius: 3,
                x: 0,
                y: 2
            )
        )
        .padding(.horizontal, 8)
    }
}



#Preview {
    
    NavigationStack {
        
        CaseHistoryListView(
            emergencyStore: EmergencyStore()
        )
    }
}
