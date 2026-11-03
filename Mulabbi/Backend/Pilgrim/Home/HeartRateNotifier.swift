import Foundation
import UserNotifications

enum HeartRateNotifier {
    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        )
    }

    static func send(for reading: HeartRateReading) async {
        let content = UNMutableNotificationContent()

        switch reading.state {
        case .high:
            content.title = localized("High Heart Rate Detected")
        case .low:
            content.title = localized("Low Heart Rate Detected")
        case .normal:
            return
        }

        content.body = String(
            format: localized("Current: %@ bpm"),
            String(reading.bpm)
        )
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private static func localized(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let bundle = Bundle.main.path(forResource: language, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main

        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
