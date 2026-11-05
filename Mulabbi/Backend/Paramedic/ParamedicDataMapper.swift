import Foundation
import MapKit

enum ParamedicDataMapper {
    
    // يجمع بيانات الحاج وسجله الطبي في نموذج المريض المستخدم في واجهة البلاغ.
    static func makeEmergencyPatient(
        pilgrim: PilgrimModel,
        medicalRecord: MedicalRecordModel
    ) -> EmergencyPatient {
        
        EmergencyPatient(
            id: pilgrim.username,
            name: pilgrim.fullName,
            username: pilgrim.username,
            phoneNumber: pilgrim.phoneNumber,
            age: pilgrim.age,
            nationality: pilgrim.nationality,
            language: pilgrim.language,
            gender: medicalRecord.gender,
            bloodType: medicalRecord.bloodType,
            chronicDiseases: medicalRecord.chronicDiseases,
            allergies: medicalRecord.allergies,
            medications: medicalRecord.medications,
            otherInfo: medicalRecord.otherInfo ?? ""
        )
    }
    
    
    // يربط بيانات المريض بإحداثيات الموقع ورقم البلاغ لعرضه على الخريطة.
    static func makeEmergencyLocation(
        alert: EmergencyAlertModel,
        location: LocationModel,
        pilgrim: PilgrimModel,
        medicalRecord: MedicalRecordModel
    ) -> EmergencyLocation {
        
        let patient = makeEmergencyPatient(
            pilgrim: pilgrim,
            medicalRecord: medicalRecord
        )
        
        return EmergencyLocation(
            alertID: alert.alertID,
            coordinate: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            ),
            type: .patient(patient)
        )
    }
    
    
    // يجهّز نموذج بلاغ المرافق مع بيانات التواصل ووصف الحالة.
    static func makeCompanionEmergencyReport(
        companionReport: CompanionReportModel,
        reporterName: String,
        reporterPhoneNumber: String
    ) -> CompanionEmergencyReport {
        
        CompanionEmergencyReport(
            id: companionReport.id,
            reporterName: reporterName,
            reporterUsername: companionReport.companionUsername,
            reporterPhoneNumber: reporterPhoneNumber,
            situationDescription: companionReport.situationDescription
        )
    }
    
    
    // يربط بلاغ المرافق بالموقع ورقم البلاغ لعرضه على الخريطة.
    static func makeCompanionEmergencyLocation(
        alert: EmergencyAlertModel,
        location: LocationModel,
        companionReport: CompanionReportModel,
        reporterName: String,
        reporterPhoneNumber: String
    ) -> EmergencyLocation {
        
        let report = makeCompanionEmergencyReport(
            companionReport: companionReport,
            reporterName: reporterName,
            reporterPhoneNumber: reporterPhoneNumber
        )
        
        return EmergencyLocation(
            alertID: alert.alertID,
            coordinate: CLLocationCoordinate2D(
                latitude: location.latitude,
                longitude: location.longitude
            ),
            type: .companion(report)
        )
    }
}
