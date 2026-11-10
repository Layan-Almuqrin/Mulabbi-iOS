import SwiftUI
import MapKit
import Combine

struct CompletedEmergency: Identifiable {
    let id = UUID()
    let emergencyID: UUID
    let type: EmergencyType
    let coordinate: CLLocationCoordinate2D
    let description: String
    let completedAt: Date
}

@MainActor
final class EmergencyStore: ObservableObject {
    private lazy var repository = ParamedicEmergencyRepository.shared
    private lazy var emergencyListener = ParamedicEmergencyListener()
    let currentParamedicUsername: String

    nonisolated init(paramedicUsername: String = "") {
        currentParamedicUsername = paramedicUsername.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @Published var emergencyLocations: [EmergencyLocation] = []
    @Published var activeEmergencyID: UUID?
    @Published var completedEmergencies: [CompletedEmergency] = []
    @Published var isLoadingEmergencies = false
    @Published var isLoadingCaseHistory = false
    @Published private(set) var isAcceptingEmergency = false
    @Published private(set) var isCompletingEmergency = false
    @Published var emergencyError: String?

    // Existing callers share this feed; reopening a screen never adds listeners.
    func loadEmergencies() async { startListeningForEmergencies() }

    func startListeningForEmergencies() {
        guard !currentParamedicUsername.isEmpty, !emergencyListener.isListening else { return }
        isLoadingEmergencies = true
        emergencyListener.start(
            paramedicUsername: currentParamedicUsername,
            onUpdate: { [weak self] locations in
                guard let self else { return }
                self.emergencyLocations = locations
                self.isLoadingEmergencies = false
            },
            onError: { [weak self] error in
                self?.isLoadingEmergencies = false
                self?.emergencyError = error.localizedDescription
            }
        )
    }

    func stopListeningForEmergencies() {
        emergencyListener.stop()
        isLoadingEmergencies = false
    }

    func loadCaseHistory() async {
        guard !currentParamedicUsername.isEmpty, !isLoadingCaseHistory else { return }
        isLoadingCaseHistory = true
        defer { isLoadingCaseHistory = false }
        do {
            completedEmergencies = try await repository.fetchCompletedEmergencies(
                paramedicUsername: currentParamedicUsername)
        } catch { emergencyError = error.localizedDescription }
    }

    /// Return success so the UI only navigates after the transaction commits.
    func acceptEmergency(emergencyID: UUID) async -> Bool {
        guard !currentParamedicUsername.isEmpty, !isAcceptingEmergency,
              let emergency = emergencyLocations.first(where: { $0.id == emergencyID }),
              let alertID = emergency.alertID else { return false }
        isAcceptingEmergency = true
        emergencyError = nil
        defer { isAcceptingEmergency = false }
        do {
            try await repository.acceptEmergency(alertID: alertID, paramedicUsername: currentParamedicUsername)
            activeEmergencyID = emergencyID
            return true
        } catch {
            emergencyError = error.localizedDescription
            return false
        }
    }

    func completeEmergency(emergencyID: UUID, description: String) async -> Bool {
        guard !currentParamedicUsername.isEmpty, !isCompletingEmergency,
              !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let emergency = emergencyLocations.first(where: { $0.id == emergencyID }),
              let alertID = emergency.alertID else { return false }
        isCompletingEmergency = true
        emergencyError = nil
        defer { isCompletingEmergency = false }
        do {
            try await repository.completeEmergency(
                alertID: alertID, paramedicUsername: currentParamedicUsername, description: description)
            completedEmergencies.insert(CompletedEmergency(
                emergencyID: emergencyID, type: emergency.type, coordinate: emergency.coordinate,
                description: description, completedAt: Date()), at: 0)
            emergencyLocations.removeAll { $0.id == emergencyID }
            if activeEmergencyID == emergencyID { activeEmergencyID = nil }
            return true
        } catch {
            emergencyError = error.localizedDescription
            return false
        }
    }
}
