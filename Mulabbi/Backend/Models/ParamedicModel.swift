import Foundation

struct ParamedicModel: Codable {
    
    var username: String
    
    var email: String
    
    var firstName: String
    
    var lastName: String
    
    var certificationFile: String?
    
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
