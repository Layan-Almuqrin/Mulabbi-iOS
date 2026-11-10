import Foundation

struct EmergencyAlertModel: Identifiable, Codable {
    
    var alertID: String
    
    var description: String
    
    var time: Date
    
    var paramedicUsername: String?
    
    var pilgrimUsername: String
    
    var companionUsername: String?
    
    
    var status: String = "pending"

    var id: String {
        alertID
    }
}
