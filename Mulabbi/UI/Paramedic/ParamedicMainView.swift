import SwiftUI

struct ParamedicMainView: View {
    
    let paramedicUsername: String
    let onLogout: () -> Void
    
    @StateObject private var emergencyStore: EmergencyStore
    
    @State private var selectedTab = 0
    @State private var homePath = NavigationPath()
    @State private var homeNavigationID = UUID()
    
    
    init(
        paramedicUsername: String,
        onLogout: @escaping () -> Void = {}
    ) {
        self.paramedicUsername = paramedicUsername
        self.onLogout = onLogout
        
        _emergencyStore = StateObject(
            wrappedValue: EmergencyStore(
                paramedicUsername: paramedicUsername
            )
        )
    }
    
    
    var body: some View {
        
        TabView(selection: $selectedTab) {
            
            NavigationStack(path: $homePath) {
                
                ParamedicHomeView(
                    emergencyStore: emergencyStore,
                    homePath: $homePath,
                    homeNavigationID: $homeNavigationID
                )
            }
            .id(homeNavigationID)
            .tabItem {
                Label(
                    "Home",
                    systemImage: "house.fill"
                )
            }
            .tag(0)
            
            
            ParamedicSettingsView(
                emergencyStore: emergencyStore,
                onLogout: onLogout
            )
            .tabItem {
                Label(
                    "Settings",
                    systemImage: "gearshape.fill"
                )
            }
            .tag(1)
        }
        .tint(Color.mulabbiMaroon)
        .toolbarBackground(
            Color.white,
            for: .tabBar
        )
        .toolbarBackground(
            .visible,
            for: .tabBar
        )
    }
}
