import SwiftUI
import FirebaseCore

@main
struct MulabbiApp: App {
    
    init(){
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
