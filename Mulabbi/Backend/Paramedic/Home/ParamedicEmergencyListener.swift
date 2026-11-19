import Foundation
import FirebaseFirestore

// اذا وصل بلاغ جديد او تحدث موقع بلاغ نحدث البلاغات على خريطة المسعف
@MainActor
final class ParamedicEmergencyListener {
    private var registrations: [ListenerRegistration] = []
    private var refreshTask: Task<Void, Never>?
    private var sessionID: UUID?
    private var revision = 0
    private var identityByAlert: [String: UUID] = [:]

    var isListening: Bool { sessionID != nil }

    func start(
        paramedicUsername: String,
        onUpdate: @escaping ([EmergencyLocation]) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        guard !isListening, !paramedicUsername.isEmpty else { return }
        let session = UUID()
        sessionID = session
        let database = Firestore.firestore()
        for collection in [ParamedicEmergencySchema.alerts, ParamedicEmergencySchema.locations] {
            let registration = database.collection(collection).addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor [weak self] in
                    guard let self, self.sessionID == session else { return }
                    if let error {
                        onError(error)
                        return
                    }
                    guard snapshot != nil else { return }
                    self.refresh(
                        paramedicUsername: paramedicUsername,
                        session: session,
                        onUpdate: onUpdate,
                        onError: onError
                    )
                }
            }
            registrations.append(registration)
        }
    }

    func stop() {
        sessionID = nil
        revision += 1
        registrations.forEach { $0.remove() }
        registrations.removeAll()
        refreshTask?.cancel()
        refreshTask = nil
    // اذا رجع المسعف للتطبيق وتفاصيل البلاغ مفتوحه نخلي رقم البلاغ نفسه عشان تظل التفاصيل مرتبطة فيه
    }

    private func refresh(
        paramedicUsername: String,
        session: UUID,
        onUpdate: @escaping ([EmergencyLocation]) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        revision += 1
        let expectedRevision = revision
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            do {
              // نحدث الخريطة مره وحده اذا وصل البلاغ وموقعه ورا بعض
                try await Task.sleep(nanoseconds: 150_000_000)
                let locations = try await ParamedicEmergencyRepository.shared
                    .fetchActiveEmergencies(paramedicUsername: paramedicUsername)
                guard let self, !Task.isCancelled,
                      self.sessionID == session,
                      self.revision == expectedRevision else { return }
                let stableLocations = locations.map { location in
                    guard let alertID = location.alertID else { return location }
                    let id = self.identityByAlert[alertID] ?? location.id
                    self.identityByAlert[alertID] = id
                    return EmergencyLocation(
                        id: id,
                        alertID: alertID,
                        paramedicUsername: location.paramedicUsername,
                        coordinate: location.coordinate,
                        type: location.type
                    )
                }
                onUpdate(stableLocations)
            } catch is CancellationError {
              
            } catch {
                guard let self, !Task.isCancelled,
                      self.sessionID == session,
                      self.revision == expectedRevision else { return }
                onError(error)
            }
        }
    }

    deinit {
        registrations.forEach { $0.remove() }
        refreshTask?.cancel()
    }
}
