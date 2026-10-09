import SwiftUI

private var companionAppLocale: Locale {
    Locale(identifier: UserDefaults.standard.string(forKey: "appLanguage") ?? "en")
}

private func companionLocalized(_ key: String) -> String {
    let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    let bundle = Bundle.main.path(forResource: language, ofType: "lproj")
        .flatMap(Bundle.init(path:)) ?? .main
    return bundle.localizedString(forKey: key, value: key, table: "Localizable")
}
import MapKit

struct CompanionSOSRequestCard: View {
    let companion: Companion
    let onOpenLocation: () -> Void
    let onDismiss: () -> Void

    private let location = CLLocationCoordinate2D(
        latitude: 21.4225,
        longitude: 39.8262
    )

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    Text(companionRequestTitle)
                        .font(.system(size: 25, weight: .bold))
                        .multilineTextAlignment(.center)

                    Text(companionDetails)
                        .font(.system(size: 18))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 28)
                .padding(.horizontal, 20)

                Map(initialPosition: .region(mapRegion)) {
                    Annotation("Companion location", coordinate: location) {
                        CompanionLocationMarker()
                    }
                }
                .mapStyle(.standard)
                .frame(height: 300)
                .allowsHitTesting(false)

                HStack(spacing: 12) {
                    alertButton("Open Location", action: onOpenLocation)
                    alertButton("OK", action: onDismiss)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay {
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            }
            .padding(.horizontal, 24)
            .shadow(color: .black.opacity(0.25), radius: 12, y: 5)
        }
    }

    private var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: location,
            span: MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
        )
    }

    private var companionRequestTitle: String {
        String(format: companionLocalized("%@ sent a help\nrequest"), locale: companionAppLocale, companion.name)
    }

    private var companionDetails: String {
        String(
            format: companionLocalized("Username: %@\nPhone number: %@"),
            locale: companionAppLocale,
            companion.username,
            companion.phoneNumber
        )
    }

    private func alertButton(_ title: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.gray.opacity(0.16))
                .clipShape(Capsule())
        }
    }
}
