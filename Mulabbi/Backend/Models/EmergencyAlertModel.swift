import Foundation

struct EmergencyAlertModel: Identifiable, Codable {
    
    var alertID: Int
    
    var description: String
    
    var time: Date
    
    var paramedicUsername: String?
    
    var pilgrimUsername: String
    
    var companionUsername: String?
    
    
    var id: Int {
        alertID
    }
}
