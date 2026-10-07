import SwiftUI

private enum ParamedicSettingsRoute {
    case overview
    case profile
    case caseHistory
}

struct ParamedicSettingsView: View {
    let onLogout: () -> Void
    
    
    
    @ObservedObject var emergencyStore: EmergencyStore
    
    
    
    
    @State private var goToCaseHistory = false
    @State private var route: ParamedicSettingsRoute = .overview
    @State private var paramedicProfile = ParamedicProfileData.sample
    
    
  
    
    init(
        emergencyStore: EmergencyStore = EmergencyStore(),
        onLogout: @escaping () -> Void = {}
    ) {
        
        self._emergencyStore = ObservedObject(
            wrappedValue: emergencyStore
        )
        self.onLogout = onLogout
    }
    
    
    private var legacyBody: some View {
        
        ZStack {
            
            
            
            AppColors.surface
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 0.93, green: 0.93, blue: 0.94))
                        .frame(height: 300)

                    Ellipse()
                        .fill(Color(red: 0.93, green: 0.93, blue: 0.94))
                        .frame(width: 560, height: 120)
                        .offset(y: 250)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 330)
                .clipped()
                Spacer()
            }
            .ignoresSafeArea(edges: .top)
            
            
            VStack(spacing: 0) {
                
                Spacer()
                    .frame(height: 76)
                
                
               
                
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 195,
                        height: 195
                    )
                    .foregroundStyle(
                        Color.gray.opacity(0.78)
                    )
                
                
               
                
                Text("Fahad Aldosari")
                    .font(
                        .system(
                            size: 30,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.black)
                    .padding(.top, 8)
                
                
               
                
                Button {
                    
                    print("Edit Profile")
                    
                } label: {
                    
                    HStack(spacing: 14) {
                        
                        EditProfileIcon()
                            .stroke(
                                Color.black,
                                style: StrokeStyle(
                                    lineWidth: 2.1,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                            .frame(
                                width: 30,
                                height: 32
                            )
                        
                        
                        Text("Edit Profile")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.black)
                        
                        
                        Spacer()
                        
                        
                        Image(systemName: "chevron.right")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                Color.black.opacity(0.80)
                            )
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(
                        
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .fill(Color.clear)
                        .overlay(
                            
                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                            .stroke(
                                AppColors.brandRed.opacity(0.75),
                                lineWidth: 1
                            )
                        )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                
                
               
                
                Button {
                    
                    goToCaseHistory = true
                    
                } label: {
                    
                    HStack(spacing: 14) {
                        
                        Image(systemName: "clipboard")
                            .font(
                                .system(
                                    size: 27,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(.black)
                        
                        
                        Text("Case History")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.black)
                        
                        
                        Spacer()
                        
                        
                        Image(systemName: "chevron.right")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                Color.black.opacity(0.80)
                            )
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 56)
                    .background(
                        
                        RoundedRectangle(
                            cornerRadius: 18,
                            style: .continuous
                        )
                        .fill(Color.clear)
                        .overlay(
                            
                            RoundedRectangle(
                                cornerRadius: 18,
                                style: .continuous
                            )
                            .stroke(
                                AppColors.brandRed.opacity(0.75),
                                lineWidth: 1
                            )
                        )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
                
                
                Spacer()
                
                
               
                
                Button {
                    
                    onLogout()
                    
                } label: {
                    
                    HStack(spacing: 9) {
                        
                        Text("Log Out")
                            .font(
                                .system(
                                    size: 26,
                                    weight: .semibold
                                )
                            )
                        
                        
                        LogoutIcon()
                            .stroke(
                                Color.white,
                                style: StrokeStyle(
                                    lineWidth: 1.8,
                                    lineCap: .round,
                                    lineJoin: .round
                                )
                            )
                            .frame(
                                width: 33,
                                height: 30
                            )
                    }
                    .foregroundStyle(.white)
                    .frame(
                        width: 185,
                        height: 58
                    )
                    .background(
                        
                        Capsule()
                            .fill(
                                Color(
                                    red: 0.72,
                                    green: 0.0,
                                    blue: 0.0
                                )
                            )
                    )
                }
                .padding(.bottom, 24)
            }
        }
        
        
       
        
        .navigationDestination(
            isPresented: $goToCaseHistory
        ) {
            
            CaseHistoryListView(
                emergencyStore: emergencyStore
            )
        }
    }

    var body: some View {
        Group {
            switch route {
            case .overview:
                SettingsMainView(
                    fullName: paramedicProfile.fullName,
                    onEditProfile: { route = .profile },
                    onEditMedicalRecord: { route = .caseHistory },
                    onLogout: onLogout,
                    secondaryTitle: "Case History",
                    secondaryIcon: "clipboard",
                    rowBorderColor: Color.gray.opacity(0.6)
                )

            case .profile:
                ParamedicEditProfileView(
                    profile: paramedicProfile,
                    onBack: { route = .overview },
                    onSave: { updatedProfile in
                        paramedicProfile = updatedProfile
                        route = .overview
                    }
                )

            case .caseHistory:
                CaseHistoryListView(
                    emergencyStore: emergencyStore,
                    onBack: { route = .overview }
                )
            }
        }
    }
}




struct EditProfileIcon: Shape {
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        
        let centerX = rect.midX
        
        let headRadius = rect.width * 0.16
        
        path.addEllipse(
            in: CGRect(
                x: centerX - headRadius,
                y: rect.height * 0.05,
                width: headRadius * 2,
                height: headRadius * 2
            )
        )
        
        
        path.move(
            to: CGPoint(
                x: rect.width * 0.18,
                y: rect.height * 0.93
            )
        )
        
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.18,
                y: rect.height * 0.76
            )
        )
        
        path.addCurve(
            to: CGPoint(
                x: rect.width * 0.82,
                y: rect.height * 0.76
            ),
            control1: CGPoint(
                x: rect.width * 0.25,
                y: rect.height * 0.52
            ),
            control2: CGPoint(
                x: rect.width * 0.75,
                y: rect.height * 0.52
            )
        )
        
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.82,
                y: rect.height * 0.93
            )
        )
        
        return path
    }
}




struct LogoutIcon: Shape {
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        
        path.addArc(
            center: CGPoint(
                x: rect.width * 0.43,
                y: rect.height * 0.50
            ),
            radius: rect.height * 0.40,
            startAngle: .degrees(55),
            endAngle: .degrees(305),
            clockwise: false
        )
        
        
        path.move(
            to: CGPoint(
                x: rect.width * 0.36,
                y: rect.height * 0.50
            )
        )
        
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.92,
                y: rect.height * 0.50
            )
        )
        
        
        path.move(
            to: CGPoint(
                x: rect.width * 0.72,
                y: rect.height * 0.27
            )
        )
        
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.92,
                y: rect.height * 0.50
            )
        )
        
        
        path.addLine(
            to: CGPoint(
                x: rect.width * 0.72,
                y: rect.height * 0.73
            )
        )
        
        return path
    }
}




#Preview {
    
    NavigationStack {
        
        ParamedicSettingsView(
            emergencyStore: EmergencyStore()
        )
    }
}
