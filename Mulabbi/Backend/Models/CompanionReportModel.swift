import Foundation

struct CompanionReportModel: Identifiable, Codable {
    
    var id: String
    
    var companionUsername: String
    
    var pilgrimUsername: String
    
    var situationDescription: String

    var isRequestForOther: Bool = false
}
