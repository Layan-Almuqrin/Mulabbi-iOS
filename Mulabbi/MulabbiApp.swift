import SwiftUI
import FirebaseCore

@main
struct MulabbiApp: App {
    
    init(){
        FirebaseApp.configure()
        HeartRateMonitor.shared.resumeMonitoringIfEnabled()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
