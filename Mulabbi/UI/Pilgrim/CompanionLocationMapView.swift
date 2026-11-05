import SwiftUI
import MapKit

struct CompanionLocationMapView: View {
    @Binding var isPresented: Bool
    let location: CLLocationCoordinate2D
    @AppStorage("appLanguage") private var appLanguage = "en"


    @State private var position: MapCameraPosition
    /// يحصل على موقع المرافق اثناء فتح الخريطه
    @StateObject private var locationManager = LocationManager()

    /// يحتفظ باخر موقع وصل للمرافق لتحديث خط المسافه
    @State private var companionLocation: CLLocationCoordinate2D?
    
    /// يحتفظ بمسار المشي الذي يتبع الطرق بين المرافق وطالب المساعدة
    @State private var walkingRoute: MKRoute?
    
    /// يحتفظ بآخر موقع استُخدم لجلب المسار حتى لا يتكرر الطلب دون حاجة
    @State private var lastRouteStart: CLLocation?
    
    /// يمنع ظهور الخريطة حتى يصل أول موقع للمرافق فتبدأ الخريطة من موقعه
    @State private var isMapReady = false

    /// يحجز موضعًا مؤقتًا للخريطة قبل وصول موقع المرافق
    init(
        isPresented: Binding<Bool>,
        location: CLLocationCoordinate2D
    ) {
        _isPresented = isPresented
        self.location = location

        let region = MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(
                latitudeDelta: 0.018,
                longitudeDelta: 0.018
            )
        )

        _position = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack {
            if isMapReady {
                Map(position: $position) {
                    /// الدائرة الحمراء تعرض موقع الشخص الذي طلب المساعدة فقط
                    Annotation("SOS location", coordinate: location) {
                        CompanionLocationMarker()
                    }

                    /// يعرض دائرة بيضاء عند موقع المرافق بدون هالة شفافة
                    if let companionLocation {
                        Annotation("Companion location", coordinate: companionLocation) {
                            CompanionCurrentLocationMarker()
                        }
                    }

                    /// يرسم مسار المشي عبر الطرق بين المرافق وطالب المساعدة
                    if let walkingRoute {
                        MapPolyline(walkingRoute.polyline)
                        .stroke(.red, lineWidth: 4)
                    }
                }
                .mapStyle(.standard)
            } else {
                ProgressView()
            }

            VStack {
                HStack {
                    if appLanguage == "ar" { Spacer() }

                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: appLanguage == "ar" ? "chevron.right" : "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.mulabbiMaroon)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.18), radius: 4, y: 3)
                    }

                    if appLanguage != "ar" { Spacer() }
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)

                Spacer()
            }
            .environment(\.layoutDirection, .leftToRight)
        }
        .ignoresSafeArea()
        
        .onAppear {
            locationManager.onAuthorized = {
                locationManager.startUpdatingLocation()
            }

            locationManager.onLocationReceived = { coordinate in
                companionLocation = coordinate
                updateWalkingRoute(from: coordinate)

                /// عند وصول أول موقع للمرافق تفتح الخريطة عنده وتُظهر موقع طالب المساعدة أيضًا
                if !isMapReady {
                    let latitudeDistance = abs(coordinate.latitude - location.latitude)
                    let longitudeDistance = abs(coordinate.longitude - location.longitude)

                    position = .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(
                                latitudeDelta: max(latitudeDistance * 2.4, 0.018),
                                longitudeDelta: max(longitudeDistance * 2.4, 0.018)
                            )
                        )
                    )
                    isMapReady = true
                }
            }

            locationManager.requestPermission()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
    }

    /// يجلب طريق المشي الفعلي بين موقع المرافق وموقع الشخص الذي طلب المساعدة.
    private func updateWalkingRoute(from companionCoordinate: CLLocationCoordinate2D) {
        let currentCompanionLocation = CLLocation(
            latitude: companionCoordinate.latitude,
            longitude: companionCoordinate.longitude
        )

        if let lastRouteStart,
           currentCompanionLocation.distance(from: lastRouteStart) < 15 {
            return
        }

        lastRouteStart = currentCompanionLocation

        let request = MKDirections.Request()
        request.source = MKMapItem(
            placemark: MKPlacemark(coordinate: companionCoordinate)
        )
        request.destination = MKMapItem(
            placemark: MKPlacemark(coordinate: location)
        )
        request.transportType = .walking

        MKDirections(request: request).calculate { response, _ in
            DispatchQueue.main.async {
                walkingRoute = response?.routes.first
            }
        }
    }
}

struct CompanionLocationMarker: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.23))
                .frame(width: 135, height: 135)
                .scaleEffect(isPulsing ? 1.08 : 0.94)
                .opacity(isPulsing ? 0.35 : 0.9)

            Circle()
                .fill(Color.red)
                .frame(width: 20, height: 20)
                .overlay {
                    Circle()
                        .stroke(.white, lineWidth: 3)
                }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

/// دائرة بيضاء تمثل موقع المرافق على الخريطة دون هالة تنبيه.
struct CompanionCurrentLocationMarker: View {
    var body: some View {
        Circle()
            .fill(.white)
            .frame(width: 20, height: 20)
            .overlay {
                Circle()
                    .stroke(.red, lineWidth: 3)
            }
    }
}

#Preview {
    CompanionLocationMapView(
        isPresented: .constant(true),
        location: CLLocationCoordinate2D(
            latitude: 21.4225,
            longitude: 39.8262
        )
    )
}
