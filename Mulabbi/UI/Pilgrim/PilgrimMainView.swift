import SwiftUI

struct PilgrimMainView: View {
    let onLogout: () -> Void
    @StateObject private var companionsStore = CompanionsStore()
    @StateObject private var companionEmergencyStore = CompanionEmergencyStore()
    @State private var selectedTab = 0
    @State private var showCompanionSOSAlert = false
    @State private var showCompanionLocation = false
    @AppStorage("currentUsername") private var currentUsername = ""

    init(onLogout: @escaping () -> Void = {}) {
        self.onLogout = onLogout
    }

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(0)

                CompanionsView(
                    store: companionsStore
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

            if showCompanionSOSAlert,
               let companion = companionEmergencyStore.activeSOSRequest,
               let location = companionEmergencyStore.activeSOSLocation {
                CompanionSOSRequestCard(
                    companion: companion,
                    location: location,
                    onOpenLocation: {
                        showCompanionSOSAlert = false
                        showCompanionLocation = true
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
            companionEmergencyStore.startReceivingRequests(
                for: currentUsername
            )
        }
        .onChange(of: companionEmergencyStore.activeSOSRequest?.id) { _, requestID in
            showCompanionSOSAlert = requestID != nil
        }
        /// يفتح خريطة موقع المساعده الحقيقي ثم يمسح بيانات الطلب بعد اغلاق الخريطة
        .fullScreenCover(
            isPresented: $showCompanionLocation,
            onDismiss: {
                companionEmergencyStore.clearSOSRequest()
            }
        ) {
            if let location = companionEmergencyStore.activeSOSLocation {
                CompanionLocationMapView(
                    isPresented: $showCompanionLocation,
                    location: location
                )
            }
        }
    }
}

#Preview {
    PilgrimMainView()
}
