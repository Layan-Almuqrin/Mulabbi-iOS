import SwiftUI
import Combine
import CoreLocation
import FirebaseFirestore

struct Companion: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let username: String
    let phoneNumber: String
    var isAlertEnabled = true
    /// رقم طلب المرافق في فايربيس
    var connectionId: String?
}


final class CompanionsStore: ObservableObject {
    @Published var companions: [Companion] = []
    @Published var requests: [Companion] = []
    /// يتواصل مع فايربيس لجلب وحفظ طلبات المرافقين
    private let companionFirebase = CompanionFirebase()
    
    /// يجلب طلبات المرافق الواردة للمستخدم ويعرضها في قائمة الطلبات
    func loadIncomingRequests(for username: String) {
        companionFirebase.fetchIncomingRequests(for: username) { result in
            DispatchQueue.main.async {
                if case .success(let requests) = result {
                    self.requests = requests
                }
            }
        }
    }
    
    /// يجلب المرافقين المقبولين للمستخدم ويعرضهم في قائمة المرافقين
    func loadAcceptedCompanions(for username: String) {
        companionFirebase.fetchAcceptedCompanions(for: username) { result in
            DispatchQueue.main.async {
                if case .success(let companions) = result {
                    self.companions = companions
                }
            }
        }
    }
    
    /// يقبل طلب المرافق ويحدث حالته في فايربيس ثم يزيله من الطلبات
    func accept(_ request: Companion) {
        guard let connectionId = request.connectionId else {
            return
        }

        companionFirebase.updateRequestStatus(
            connectionId: connectionId,
            status: "accepted"
        ) { result in
            DispatchQueue.main.async {
                if case .success = result {
                    self.requests.removeAll { $0.id == request.id }

                    if !self.companions.contains(where: {
                        $0.phoneNumber == request.phoneNumber
                    }) {
                        self.companions.append(request)
                    }
                }
            }
        }
    }

    /// يرفض طلب المرافق ويحدث حالته في فايربيس ثم يزيله من الطلبات
    func reject(_ request: Companion) {
        guard let connectionId = request.connectionId else {
            return
        }

        companionFirebase.updateRequestStatus(
            connectionId: connectionId,
            status: "rejected"
        ) { result in
            DispatchQueue.main.async {
                if case .success = result {
                    self.requests.removeAll { $0.id == request.id }
                }
            }
        }
    }
    
    /// يغيّر حالة استلام التنبيهات للمرافق ويحفظ الحالة الجديدة في فايربيس
    func toggleAlert(for companion: Companion) {
        guard let index = companions.firstIndex(where: {
            $0.id == companion.id
        }) else {
            return
        }

        companions[index].isAlertEnabled.toggle()

        guard let connectionId = companions[index].connectionId else {
            return
        }

        companionFirebase.updateAlertStatus(
            connectionId: connectionId,
            isAlertEnabled: companions[index].isAlertEnabled
        )
    }
}

/// يدير وصول طلبات مساعده للمرافق ويعرض الطلب الحالي في الواجهة
final class CompanionEmergencyStore: ObservableObject {
    @Published var activeSOSRequest: Companion?
    @Published var activeSOSAlertId: String?
    @Published var activeSOSLocation: CLLocationCoordinate2D?

    private let emergencyAlertFirebase = EmergencyAlertFirebase()
    private let companionFirebase = CompanionFirebase()
    private var requestListener: ListenerRegistration?

    /// يبدأ متابعة طلبات الطوارئ الموجهة للمرافق الحالي
    func startReceivingRequests(for companionUsername: String) {
        requestListener?.remove()

        requestListener = emergencyAlertFirebase.receiveRequest(
            for: companionUsername
        ) { [weak self] alertId, pilgrimUsername in
            guard let self, self.activeSOSAlertId != alertId else {
                return
            }

            self.companionFirebase.findPilgrim(
                byUsername: pilgrimUsername
            ) { result in
                guard case .success(let pilgrim) = result,
                      let pilgrim
                else {
                    return
                }

                self.emergencyAlertFirebase.fetchAlertLocation(
                    alertId: alertId
                ) { locationResult in
                    DispatchQueue.main.async {
                        switch locationResult {
                        case .success(let location):
                            self.activeSOSLocation = location

                        case .failure:
                            self.activeSOSLocation = nil
                        }

                        self.activeSOSAlertId = alertId
                        self.activeSOSRequest = pilgrim
                    }
                }
            }
        }
    }

    func receiveSOS(from companion: Companion) {
        activeSOSRequest = companion
    }

    func clearSOSRequest() {
        activeSOSRequest = nil
        activeSOSAlertId = nil
        activeSOSLocation = nil
    }
}
