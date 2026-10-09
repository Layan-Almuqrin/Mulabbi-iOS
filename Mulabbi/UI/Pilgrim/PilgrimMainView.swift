import SwiftUI

struct PilgrimMainView: View {
    let onLogout: () -> Void
    @StateObject private var companionsStore = CompanionsStore()
    @StateObject private var companionEmergencyStore = CompanionEmergencyStore()
    @State private var selectedTab = 0
    @State private var showCompanionSOSAlert = false
    @State private var showCompanionLocation = false

    init(onLogout: @escaping () -> Void = {}) {
        self.onLogout = onLogout
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView(emergencyStore: companionEmergencyStore)
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                CompanionsView(
                    store: companionsStore,
                    emergencyStore: companionEmergencyStore,
                    onIncomingSOS: { }
                )
                    .tabItem { Label("Companions", systemImage: "person.2.fill") }
                    .tag(1)

                ChatbotView()
                    .tabItem {
                        Label {
                            Text("Chatbot")
                        } icon: {
                            Image("ChatbotRobot")
                                .resizable()
                                .renderingMode(.template)
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                    }
                    .tag(2)

                SettingsView(onLogout: onLogout)
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                    .tag(3)
            }

            if showCompanionSOSAlert, let companion = companionEmergencyStore.activeSOSRequest {
                CompanionSOSRequestCard(
                    companion: companion,
                    onOpenLocation: {
                        showCompanionSOSAlert = false
                        showCompanionLocation = true
                        companionEmergencyStore.clearSOSRequest()
                    },
                    onDismiss: {
                        showCompanionSOSAlert = false
                        companionEmergencyStore.clearSOSRequest()
                    }
                )
            }
        }
        .tint(Color.mulabbiMaroon)
        .onAppear {
            showCompanionSOSAlert = companionEmergencyStore.activeSOSRequest != nil
        }
        .onChange(of: companionEmergencyStore.activeSOSRequest?.id) { _, requestID in
            showCompanionSOSAlert = requestID != nil
        }
        .fullScreenCover(isPresented: $showCompanionLocation) {
            CompanionLocationMapView(isPresented: $showCompanionLocation)
        }
    }
}

#Preview {
    PilgrimMainView()
}
