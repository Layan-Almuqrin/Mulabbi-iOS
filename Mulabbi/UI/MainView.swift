import SwiftUI

private enum AppScreen {
    case welcome
    case roleSelection
    case pilgrimLogin
    case paramedicLogin
    case pilgrimApp
    case paramedicApp
}

struct MainView: View {
    
    @AppStorage("appLanguage") private var appLanguage = "en"
    
    @State private var screen: AppScreen = .welcome

    var body: some View {
        
        Group {
            
            switch screen {
                
            case .welcome:
                
                WelcomeView {
                    screen = .roleSelection
                }
                
                
            case .roleSelection:
                
                RoleSelectionView(
                    onSelectParamedic: {
                        screen = .paramedicLogin
                    },
                    onSelectPilgrim: {
                        screen = .pilgrimLogin
                    }
                )
                
                
            case .pilgrimLogin:
                
                PilgrimLoginView(
                    onLogin: {
                        screen = .pilgrimApp
                    },
                    onBack: {
                        screen = .roleSelection
                    }
                )
                
                
            case .paramedicLogin:
                
                ParamedicLoginView(
                    onLogin: {
                        screen = .paramedicApp
                    },
                    onBack: {
                        screen = .roleSelection
                    }
                )
                
                
            case .pilgrimApp:
                
                PilgrimMainView(
                    onLogout: {
                        screen = .roleSelection
                    }
                )
                
                
            case .paramedicApp:
                
                ParamedicMainView(
                    onLogout: {
                        screen = .roleSelection
                    }
                )
            }
        }
        .environment(
            \.locale,
            Locale(identifier: appLanguage)
        )
        .environment(
            \.layoutDirection,
            appLanguage == "ar"
            ? .rightToLeft
            : .leftToRight
        )
    }
}



private struct WelcomeView: View {
    
    let continueAction: () -> Void

    var body: some View {
        
        ZStack {
            
            
            Color.mulabbiRoseTint

            GeometryReader { proxy in
                
                Image("SplashWelcome")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .scaleEffect(1.06)
                    .offset(y: 16)
                    .clipped()
            }
        }
        .ignoresSafeArea()
        .task {
            
            try? await Task.sleep(
                for: .seconds(1.5)
            )
            
            guard !Task.isCancelled else {
                return
            }
            
            continueAction()
        }
    }
}



#Preview {
    MainView()
}
