import Foundation
import CoreLocation
import Turf

/// يتحقق هل موقع المستخدم داخل حدود الخدمة المسموح بها
final class AllowedAreaValidator {
    
    private let serviceBoundary = AllowedAreaValidator.loadPolygons(named: "ServiceBoundary")
    private let holySitesBoundary = AllowedAreaValidator.loadPolygons(named: "HolySitesBoundary")
    
    /// إذا كان الموقع داخل الحرم أو داخل المشاعر خلال شهر ذي الحجة يرجع true
    func isLocationAllowed(
        _ coordinate: CLLocationCoordinate2D,
        date: Date = Date()
    ) -> Bool {
        if Self.contains(coordinate, in: serviceBoundary) {
            return true
        }
        
        /// اذا لم يكن داخل حدود الحرم يتاكد هل نحن في شهر ذي الحجة
        guard Self.isDhulHijjah(date) else {
            return false
        }
        
        /// اذا كان الشهر ذي الحجة يتاكد هل هو داخل مشاعر الحج
        return Self.contains(coordinate, in: holySitesBoundary)
    }
    
    /// للتحقق من ان الشهر هو ذي الحجة
    private static func isDhulHijjah(_ date: Date) -> Bool {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh") ?? .current
        
        return calendar.component(.month, from: date) == 12
    }
    
    /// يحول ملف الحدود الى مناطق يستطاع التحقق منها
    private static func loadPolygons(named fileName: String) -> [Polygon] {
        guard
            let url = Bundle.main.url(
                forResource: fileName,
                withExtension: "geojson"
            ),
            let data = try? Data(contentsOf: url),
            let collection = try? GeoJSON.parse(
                FeatureCollection.self,
                from: data
            )
        else {
            return []
        }
        
        return collection.features.compactMap { feature in
            guard case let .polygon(polygon) = feature.geometry else {
                return nil
            }
            
            return polygon
        }
    }
    
    /// يتحقق هل احداثية المستخدم موجودة داخل واحدة من المناطق المحددة
    private static func contains(
        _ coordinate: CLLocationCoordinate2D,
        in polygons: [Polygon]
    ) -> Bool {
        polygons.contains { polygon in
            polygon.contains(coordinate)
        }
    }
}
