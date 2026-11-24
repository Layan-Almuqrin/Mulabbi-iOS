import SwiftUI
import FirebaseCore
import UIKit

@MainActor
final class MulabbiAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        HeartRateMonitor.shared.resumeMonitoringIfEnabled()
        return true
    }
}

@main
struct MulabbiApp: App {
    @UIApplicationDelegateAdaptor(MulabbiAppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
