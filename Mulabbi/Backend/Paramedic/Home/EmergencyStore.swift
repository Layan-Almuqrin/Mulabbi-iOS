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




final class EmergencyStore: ObservableObject {
    
   
    
    @Published var emergencyLocations: [EmergencyLocation] = [
        
        
        
        EmergencyLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 21.4277,
                longitude: 39.8208
            ),
            type: .patient(
                EmergencyPatient(
                    id: "patient_001",
                    name: "Shatha Alessa",
                    username: "Shatha77m",
                    phoneNumber: "0556786799",
                    age: 20,
                    nationality: "British",
                    language: "English",
                    gender: "Female",
                    bloodType: "O+",
                    chronicDiseases: "Diabetes (Type2)",
                    allergies: "Penicillin",
                    medications: "Metformin",
                    otherInfo: "I carry insulin with me and may need it in emergencies"
                )
            )
        ),
        
        
       
        
        EmergencyLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 21.4267,
                longitude: 39.8320
            ),
            type: .companion(
                CompanionEmergencyReport(
                    id: "report_001",
                    reporterName: "Shatha Alessa",
                    reporterUsername: "Shatha77m",
                    reporterPhoneNumber: "0556786799",
                    situationDescription:
                    """
                    I saw a woman sitting on the ground who looked very tired. She was holding her chest and having difficulty breathing. She seemed confused and was unable to stand. Her face looked pale, and she was sweating noticeably. She told me that the chest pain started suddenly a short while ago. She was speaking with difficulty and her voice was weak, and every time she tried to take a breath, she seemed to struggle more. I did not notice any visible injuries, so I reported the situation immediately.
                    """
                )
            )
        ),
        
        
       
        
        EmergencyLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: 21.4152,
                longitude: 39.8248
            ),
            type: .patient(
                EmergencyPatient(
                    id: "patient_002",
                    name: "Ahmed Ali",
                    username: "AhmedAli45",
                    phoneNumber: "0501234567",
                    age: 45,
                    nationality: "Saudi",
                    language: "Arabic",
                    gender: "Male",
                    bloodType: "A+",
                    chronicDiseases: "None",
                    allergies: "None",
                    medications: "None",
                    otherInfo: "No additional medical information"
                )
            )
        )
    ]
    
    
  
    
    @Published var completedEmergencies: [CompletedEmergency] = []
    
    
   
    
    func completeEmergency(
        emergencyID: UUID,
        description: String
    ) {
        
        guard let emergency = emergencyLocations.first(
            where: {
                $0.id == emergencyID
            }
        ) else {
            return
        }
        
        
        let completedEmergency = CompletedEmergency(
            emergencyID: emergency.id,
            type: emergency.type,
            coordinate: emergency.coordinate,
            description: description,
            completedAt: Date()
        )
        
        
        completedEmergencies.append(
            completedEmergency
        )
        
        
        emergencyLocations.removeAll {
            $0.id == emergencyID
        }
    }
}
