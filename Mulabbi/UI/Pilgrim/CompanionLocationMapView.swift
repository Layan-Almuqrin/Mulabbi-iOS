import SwiftUI
import MapKit

struct CompanionLocationMapView: View {
    @Binding var isPresented: Bool
    @AppStorage("appLanguage") private var appLanguage = "en"

    private let companionLocation = CLLocationCoordinate2D(
        latitude: 21.4225,
        longitude: 39.8262
    )

    @State private var position: MapCameraPosition

    init(isPresented: Binding<Bool>) {
        _isPresented = isPresented
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262),
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
        _position = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack(alignment: appLanguage == "ar" ? .topTrailing : .topLeading) {
            Map(position: $position) {
                Annotation("Companion location", coordinate: companionLocation) {
                    CompanionLocationMarker()
                }
            }
            .mapStyle(.standard)

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
            .padding(appLanguage == "ar" ? .trailing : .leading, 22)
            .padding(.top, 64)
        }
        .ignoresSafeArea()
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

            LocationPin()
                .frame(width: 35, height: 44)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.15).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#Preview {
    CompanionLocationMapView(isPresented: .constant(true))
}
