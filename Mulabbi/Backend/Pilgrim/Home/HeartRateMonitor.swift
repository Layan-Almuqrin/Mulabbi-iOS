import Combine
import Foundation
@preconcurrency import HealthKit

enum HeartRateState: Equatable {
    case normal
    case high
    case low
}

struct HeartRateReading {
    let bpm: Int
    let state: HeartRateState
}

enum HeartRateMonitorError: Error {
    case healthDataUnavailable
    case heartRateTypeUnavailable
}

@MainActor
final class HeartRateMonitor: ObservableObject {
    static let shared = HeartRateMonitor()

    @Published private(set) var alertReading: HeartRateReading?

    private let healthStore = HKHealthStore()
    private let lowerLimit = 60
    private var upperLimit = 100
    private let upperLimitKey = "heartRateUpperLimit"
    private var observerQuery: HKObserverQuery?
    private var lastState: HeartRateState = .normal
    private var lastProcessedSampleDate: Date?

    private init() {}

    func connect(age: Int) async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HeartRateMonitorError.healthDataUnavailable
        }

        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HeartRateMonitorError.heartRateTypeUnavailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: [heartRateType])
        await HeartRateNotifier.requestPermission()

        updateAge(age)
        UserDefaults.standard.set(true, forKey: "heartRateMonitoringEnabled")
        startMonitoring(fetchCurrentReading: true)
    }

    func updateAge(_ age: Int) {
        guard age >= 15 else { return }
        upperLimit = Int(((208.0 - (0.7 * Double(age))) * 0.85).rounded())
        UserDefaults.standard.set(upperLimit, forKey: upperLimitKey)
    }

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

    func disconnect() {
        if let observerQuery {
            healthStore.stop(observerQuery)
        }

        if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            healthStore.disableBackgroundDelivery(for: heartRateType) { _, _ in }
        }

        observerQuery = nil
        alertReading = nil
        lastState = .normal
        lastProcessedSampleDate = nil
        UserDefaults.standard.set(false, forKey: "heartRateMonitoringEnabled")
    }

    func dismissAlert() {
        alertReading = nil
    }

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
            defer { completion() }
            guard error == nil else { return }

            Task { @MainActor in
                self?.fetchLatestReading(heartRateType)
            }
        }

        observerQuery = query
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { _, _ in }

        if fetchCurrentReading {
            fetchLatestReading(heartRateType)
        }
    }

    private func fetchLatestReading(_ heartRateType: HKQuantityType) {
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
                return
            }

            let unit = HKUnit.count().unitDivided(by: .minute())
            let bpm = Int(sample.quantity.doubleValue(for: unit).rounded())
            let sampleDate = sample.endDate

            Task { @MainActor in
                self?.process(bpm: bpm, sampleDate: sampleDate)
            }
        }

        healthStore.execute(query)
    }

    private func process(bpm: Int, sampleDate: Date) {
        guard lastProcessedSampleDate != sampleDate else { return }
        lastProcessedSampleDate = sampleDate

        let state: HeartRateState

        if bpm > upperLimit {
            state = .high
        } else if bpm < lowerLimit {
            state = .low
        } else {
            state = .normal
        }

        guard state != .normal else {
            lastState = .normal
            return
        }

        guard state != lastState else { return }
        lastState = state

        let reading = HeartRateReading(
            bpm: bpm,
            state: state
        )

        alertReading = reading

        Task {
            await HeartRateNotifier.send(for: reading)
        }
    }
}
