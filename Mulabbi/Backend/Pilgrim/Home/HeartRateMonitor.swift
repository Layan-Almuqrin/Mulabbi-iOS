import Combine
import Foundation
@preconcurrency import HealthKit

/// حالات نبض القلب المستخدمة لتحديد نوع التنبيه
enum HeartRateState: Equatable {
    case normal
    case high
    case low
}

/// تحتوي على عدد نبضات القلب وحالتها
struct HeartRateReading {
    let bpm: Int
    let state: HeartRateState
}

/// الأخطاء التي قد تمنع بدء متابعة نبض القلب
enum HeartRateMonitorError: Error {
    case healthDataUnavailable
    case heartRateTypeUnavailable
}

@MainActor
/// مسؤول عن الاتصال ببيانات الصحة ومتابعة أحدث قراءة لنبض القلب
final class HeartRateMonitor: ObservableObject {
    static let shared = HeartRateMonitor()

    /// القراءة غير الطبيعية التي يعرضها التطبيق
    @Published private(set) var alertReading: HeartRateReading?

    private let healthStore = HKHealthStore()
    private let lowerLimit = 60
    private var upperLimit: Int?
    private let upperLimitKey = "heartRateUpperLimit"
    private var observerQuery: HKObserverQuery?

    /// تمنع تكرار التنبيه إذا لم يتغير رقم النبض
    private var lastBPM: Int?

    private init() {}

    /// يطلب الصلاحيات ويحسب الحد الأعلى ثم يبدأ المتابعة
    func connect(age: Int) async throws {
        /// يتأكد أن بيانات الصحة متاحة على الجهاز
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HeartRateMonitorError.healthDataUnavailable
        }

        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HeartRateMonitorError.heartRateTypeUnavailable
        }

        /// يطلب صلاحية قراءة النبض وإرسال الإشعارات
        try await healthStore.requestAuthorization(toShare: [], read: [heartRateType])
        await HeartRateNotifier.requestPermission()

        /// يحفظ حالة الربط ثم يبدأ متابعة النبض
        updateAge(age)
        UserDefaults.standard.set(true, forKey: "heartRateMonitoringEnabled")
        startMonitoring(fetchCurrentReading: true)
    }

    /// يحسب الحد الأعلى حسب العمر ويحفظه
    func updateAge(_ age: Int) {
        guard age >= 15 else { return }

        /// معادلة حساب الحد الأعلى لمعدل نبض القلب
        let calculatedUpperLimit = Int(((208.0 - (0.7 * Double(age))) * 0.85).rounded())
        upperLimit = calculatedUpperLimit
        UserDefaults.standard.set(calculatedUpperLimit, forKey: upperLimitKey)
    }

    /// يعيد تشغيل المتابعة إذا سبق للمستخدم تفعيلها
    func resumeMonitoringIfEnabled() {
        guard UserDefaults.standard.bool(forKey: "heartRateMonitoringEnabled") else {
            return
        }

        let savedUpperLimit = UserDefaults.standard.integer(forKey: upperLimitKey)
        if savedUpperLimit > 0 {
            upperLimit = savedUpperLimit
        }
        startMonitoring(fetchCurrentReading: false)
    }

    /// يوقف متابعة النبض والتحديثات في الخلفية
    func disconnect() {
        if let observerQuery {
            healthStore.stop(observerQuery)
        }

        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            healthStore.disableBackgroundDelivery(for: heartRateType) { _, _ in }
        }

        observerQuery = nil
        alertReading = nil
        lastBPM = nil
        UserDefaults.standard.set(false, forKey: "heartRateMonitoringEnabled")
    }

    /// يخفي تنبيه النبض الظاهر داخل التطبيق
    func dismissAlert() {
        alertReading = nil
    }

    /// يبدأ مراقبة وصول عينات نبض جديدة من بيانات الصحة
    private func startMonitoring(fetchCurrentReading: Bool) {
        guard observerQuery == nil,
              let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)
        else {
            return
        }

        let query = HKObserverQuery(
            sampleType: heartRateType,
            predicate: nil
        ) { [weak self] _, completion, error in
            guard error == nil else {
                completion()
                return
            }

            Task { @MainActor in
                guard let self else {
                    completion()
                    return
                }

                self.fetchLatestReading(heartRateType, completion: completion)
            }
        }

        observerQuery = query
        healthStore.execute(query)

        /// يسمح بتنبيه التطبيق عند وصول قراءة جديدة في الخلفية
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { _, _ in }

        if fetchCurrentReading {
            fetchLatestReading(heartRateType)
        }
    }

    /// يجلب أحدث عينة نبض فقط
    private func fetchLatestReading(
        _ heartRateType: HKQuantityType,
        completion: (() -> Void)? = nil
    ) {
        let newestFirst = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [newestFirst]
        ) { [weak self] _, samples, error in
            guard error == nil,
                  let sample = samples?.first as? HKQuantitySample
            else {
                completion?()
                return
            }

            let unit = HKUnit.count().unitDivided(by: .minute())

            /// يحول القراءة إلى عدد نبضات في الدقيقة
            let bpm = Int(sample.quantity.doubleValue(for: unit).rounded())

            Task { @MainActor in
                if let self {
                    await self.process(bpm: bpm)
                }
                completion?()
            }
        }

        healthStore.execute(query)
    }

    /// يصنف القراءة وينبه فقط عند ارتفاعها أو انخفاضها
    private func process(bpm: Int) async {
        guard let upperLimit else { return }
        guard bpm != lastBPM else { return }
        lastBPM = bpm

        let state: HeartRateState

        if bpm > upperLimit {
            state = .high
        } else if bpm < lowerLimit {
            state = .low
        } else {
            state = .normal
        }

        guard state != .normal else { return }

        let reading = HeartRateReading(
            bpm: bpm,
            state: state
        )

        /// يثبت التنبيه الداخلي الحالي حتى يغلقه المستخدم
        if alertReading == nil {
            alertReading = reading
        }

        /// يرسل التنبيه نفسه كإشعار خارج التطبيق
        await HeartRateNotifier.send(for: reading)
    }

}
