import SwiftUI

struct ParamedicMainView: View {
    
    let paramedicUsername: String
    let onLogout: () -> Void
    
    @Environment(\.scenePhase) private var scenePhase
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
                onLogout: {
                    emergencyStore.stopListeningForEmergencies()
                    onLogout()
                }
            )
            .tabItem {
                Label(
                    "Settings",
                    systemImage: "gearshape.fill"
                )
            }
            .tag(1)
        }
        .onAppear { emergencyStore.startListeningForEmergencies() }
        .onDisappear { emergencyStore.stopListeningForEmergencies() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                emergencyStore.startListeningForEmergencies()
            } else if phase == .background {
                emergencyStore.stopListeningForEmergencies()
            }
        }
        .alert("Unable to update request", isPresented: Binding(
            get: { emergencyStore.emergencyError != nil },
            set: { if !$0 { emergencyStore.emergencyError = nil } }
        )) {
            Button("OK", role: .cancel) { emergencyStore.emergencyError = nil }
        } message: {
            Text(emergencyStore.emergencyError ?? "")
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
