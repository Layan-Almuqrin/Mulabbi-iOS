import SwiftUI
import Combine

struct Companion: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let username: String
    let phoneNumber: String
}

final class CompanionsStore: ObservableObject {
    @Published var companions: [Companion] = [
        Companion(name: "Atheer Alhashel", username: "Atheer7", phoneNumber: "0556786799")
    ]

    @Published var requests: [Companion] = [
        Companion(name: "Layan Almuqrin", username: "mLayan80", phoneNumber: "0578045799")
    ]

    func accept(_ request: Companion) {
        requests.removeAll { $0.id == request.id }
        if !companions.contains(where: { $0.phoneNumber == request.phoneNumber }) {
            companions.append(request)
        }
    }

    func reject(_ request: Companion) {
        requests.removeAll { $0.id == request.id }
    }
}


/// notfication when a companion sent SOS 
final class CompanionEmergencyStore: ObservableObject {
    @Published var activeSOSRequest: Companion?

    func receiveSOS(from companion: Companion) {
        activeSOSRequest = companion
    }

    func clearSOSRequest() {
        activeSOSRequest = nil
    }
}
