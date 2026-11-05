import Foundation

enum CaseHistoryType: String, Codable {
    
    case patient
    
    case companion
}


struct CaseHistoryModel: Identifiable, Codable {
    
    var id: String
    
    var alertID: Int
    
    var paramedicUsername: String
    
    var pilgrimUsername: String
    
    var companionUsername: String?
    
    var caseType: CaseHistoryType
    
    var assistanceProvided: String
    
    var completedAt: Date
}
