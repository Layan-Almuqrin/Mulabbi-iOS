import Foundation

struct PilgrimModel: Codable {
    
    var username: String
    
    var email: String
    
    var nationality: String
    
    var language: String
    
    var age: Int
    
    var firstName: String
    
    var lastName: String
    
    var phoneNumber: String
    
    var heartRate: Double?
    
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
}
