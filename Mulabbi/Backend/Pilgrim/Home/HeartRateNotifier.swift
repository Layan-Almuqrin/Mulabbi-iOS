import Foundation
import UserNotifications

/// مسؤول عن طلب صلاحية الإشعارات وإرسال تنبيهات نبض القلب
enum HeartRateNotifier {
    /// يطلب السماح بإظهار التنبيهات وتشغيل صوتها
    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound]
        )
    }

    /// يجهز ويرسل إشعارًا عند ارتفاع قراءة النبض أو انخفاضها
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

        /// يضيف قراءة النبض الحالية إلى نص الإشعار
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

    /// يختار نص الإشعار حسب لغة التطبيق
    private static func localized(_ key: String) -> String {
        let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        let bundle = Bundle.main.path(forResource: language, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main

        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
