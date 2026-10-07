import SwiftUI
import UIKit


private var appLocale: Locale {
    Locale(identifier: UserDefaults.standard.string(forKey: "appLanguage") ?? "en")
}

private func appLocalized(_ key: String) -> String {
    let language = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    let bundle = Bundle.main.path(forResource: language, ofType: "lproj")
        .flatMap(Bundle.init(path:)) ?? .main
    return bundle.localizedString(forKey: key, value: key, table: "Localizable")
}

private enum PendingAction {
    case sos
    case requestForOthers
}

private enum HomeAlert: Identifiable {
    case locationNeeded, confirmSOS, paramedicOnWay, confirmOthers, requestSent, disconnectWatch

    var id: String {
        switch self {
        case .locationNeeded: "locationNeeded"
        case .confirmSOS: "confirmSOS"
        case .paramedicOnWay: "paramedicOnWay"
        case .confirmOthers: "confirmOthers"
        case .requestSent: "requestSent"
        case .disconnectWatch: "disconnectWatch"
        }
    }

    var title: String {
        switch self {
        case .locationNeeded: appLocalized("Location Needed")
        case .confirmSOS: appLocalized("Are you sure you want to send an SOS?")
        case .paramedicOnWay: appLocalized("A paramedic is on the way to help you.")
        case .confirmOthers: appLocalized("Are you sure you want to send help to another person?")
        case .requestSent: appLocalized("A paramedic is on the way to help you.")
        case .disconnectWatch: appLocalized("Disconnect Apple Watch?")
        }
    }

    var message: String? {
        switch self {
        case .locationNeeded:
            appLocalized("Please enable your location so we can send help to you.")
        case .confirmOthers:
            appLocalized("Your phone number and location will be shared with paramedics.")
        case .disconnectWatch:
            appLocalized("Heart rate monitoring and notifications will stop.")
        default:
            nil
        }
    }

}

struct HomeView: View {
    @AppStorage("appLanguage") private var appLanguage = "en"
    @StateObject private var locationManager = LocationManager()
    @ObservedObject var emergencyStore: CompanionEmergencyStore

    @State private var pendingAction: PendingAction?
    @State private var activeAlert: HomeAlert?
    @State private var showRequestDetailsSheet = false
    @State private var requestDetails = ""
    @State private var isWatchConnected = false
    @State private var showHeartRateAlert = false
    @State private var isSOSPulsing = false
    private let userName = "Shatha"

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                sosButton
                    .padding(.top, 8)

                requestForOthersButton
                    .padding(.bottom, 30)

                appleWatchCard

                Spacer(minLength: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .overlay {
            ZStack {
                if let alert = activeAlert {
                    HomeAlertOverlay(
                        alert: alert,
                        onPrimary: {
                            activeAlert = nil
                            DispatchQueue.main.async {
                                handlePrimaryAlertAction(alert)
                            }
                        },
                        onSecondary: {
                            activeAlert = nil
                            DispatchQueue.main.async {
                                dismissHomeAlert()
                            }
                        }
                    )
                    .zIndex(4)
                }

                if showHeartRateAlert {
                    HeartRateSystemAlert {
                        showHeartRateAlert = false
                    }
                    .zIndex(5)
                }

            }
        }
        .sheet(isPresented: $showRequestDetailsSheet) {
            RequestForOthersDetailsView(details: $requestDetails) {
                showRequestDetailsSheet = false
                requestDetails = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    activeAlert = .requestSent
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            configureLocationCallbacks()
        }
    }

    private var header: some View {
        HStack {
            Circle()
                .fill(Color(.systemGray4))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "person.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                )

            Text(String(format: appLocalized("Welcome %@ !"), locale: appLocale, userName))
                .font(.system(size: 23, weight: .semibold))
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    private var sosButton: some View {
        GeometryReader { proxy in
            let size = proxy.size.width * 0.91
            Button {
                beginFlow(.sos)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.mulabbiMaroon.opacity(0.08))
                        .frame(width: size, height: size)
                        .scaleEffect(isSOSPulsing ? 1.10 : 0.94)
                        .opacity(isSOSPulsing ? 0.20 : 0.90)

                    Circle()
                        .fill(Color.mulabbiRose.opacity(0.50))
                        .frame(width: size * 0.88, height: size * 0.88)
                        .scaleEffect(isSOSPulsing ? 1.06 : 0.96)
                        .opacity(isSOSPulsing ? 0.40 : 0.90)

                    Circle()
                        .fill(Color.mulabbiRose.opacity(0.72))
                        .frame(width: size * 0.78, height: size * 0.78)
                        .scaleEffect(isSOSPulsing ? 1.03 : 0.98)

                    Circle()
                        .fill(Color.mulabbiMaroon)
                        .frame(width: size * 0.68, height: size * 0.68)

                    Text("SOS")
                        .font(.system(size: size * (appLanguage == "ar" ? 0.105 : 0.15), weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(.plain)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                    isSOSPulsing = true
                }
            }
        }
        .frame(height: 350)
    }

    private var requestForOthersButton: some View {
        Button {
            beginFlow(.requestForOthers)
        } label: {
            Text("Request Help for Others")
                .font(.system(size: appLanguage == "ar" ? 15 : 16, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, 24)
                .padding(.vertical, 13)
                .background(Color.mulabbiMaroon)
                .clipShape(Capsule())
        }
        .padding(.bottom, 15)
    }
    private var appleWatchCard: some View {
        VStack(alignment: appLanguage == "ar" ? .trailing : .leading, spacing: 8) {
            if appLanguage == "ar" {
                HStack {
                    Spacer()
                    Text("Apple Watch")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                }
                .environment(\.layoutDirection, .leftToRight)
            } else {
                Text("Apple Watch")
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(.black)
            }

            ZStack(alignment: .bottomTrailing) {
                HStack(alignment: .top, spacing: 12) {
                    Image("AppleWatch")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 68, height: 84)

                    VStack(alignment: appLanguage == "ar" ? .trailing : .leading, spacing: 7) {
                        Text("Connect your Apple Watch")
                            .font(.system(size: appLanguage == "ar" ? 17 : 19, weight: .bold))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                            .frame(maxWidth: .infinity, alignment: appLanguage == "ar" ? .trailing : .leading)

                        Text("Monitors your heart rate and notifies you when an abnormal reading is detected.")
                            .font(.system(size: appLanguage == "ar" ? 13 : 10.5))
                            .foregroundStyle(.black)
                            .lineSpacing(2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.9)
                            .multilineTextAlignment(appLanguage == "ar" ? .trailing : .leading)
                            .frame(maxWidth: .infinity, alignment: appLanguage == "ar" ? .trailing : .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: appLanguage == "ar" ? .trailing : .leading)
                    .environment(\.layoutDirection, .leftToRight)
                }

                Button {
                    if isWatchConnected {
                        activeAlert = .disconnectWatch
                    } else {
                        isWatchConnected = true
                        showAutomaticHeartRateAlert()
                    }
                } label: {
                    Text(appLocalized(isWatchConnected ? "Disconnect" : "Connect"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 78, height: 34)
                        .background(Color.mulabbiMaroon)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 15)
            .background(Color.mulabbiRoseTint)
            .clipShape(RoundedRectangle(cornerRadius: 18))

        }
    }

    private func showAutomaticHeartRateAlert() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            guard isWatchConnected else { return }
            showHeartRateAlert = true
        }
    }

    private func configureLocationCallbacks() {
        locationManager.onAuthorized = {
            handleAuthorized()
        }

        locationManager.onDenied = {
            handleDenied()
        }
    }

    private func dismissHomeAlert() {
        activeAlert = nil
        pendingAction = nil
    }

    private func handlePrimaryAlertAction(_ alert: HomeAlert) {
        switch alert {
        case .locationNeeded:
            continueAfterLocationCheck()
        case .confirmSOS:
            dispatchParamedic()
        case .paramedicOnWay, .requestSent:
            dismissHomeAlert()
        case .confirmOthers:
            showRequestDetailsSheet = true
        case .disconnectWatch:
            isWatchConnected = false
            dismissHomeAlert()
        }
    }

    private func beginFlow(_ action: PendingAction) {
        configureLocationCallbacks()
        pendingAction = action
        locationManager.requestPermission()
    }

    private func handleAuthorized() {
        switch pendingAction {
        case .sos:
            activeAlert = .confirmSOS

        case .requestForOthers:
            activeAlert = .confirmOthers

        case .none:
            break
        }
    }

    private func handleDenied() {
        activeAlert = .locationNeeded
    }

    private func dispatchParamedic() {
        activeAlert = nil
        DispatchQueue.main.async {
            activeAlert = .paramedicOnWay
        }
    }

    private func continueAfterLocationCheck() {
        switch pendingAction {
        case .sos:
            activeAlert = .confirmSOS

        case .requestForOthers:
            activeAlert = .confirmOthers

        case .none:
            break
        }
    }
}

private struct HomeAlertOverlay: View {
    let alert: HomeAlert
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text(alert.title)
                    .font(.system(size: 21, weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                if let message = alert.message {
                    Text(message)
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                if let secondaryTitle {
                    HStack(spacing: 12) {
                        alertButton(secondaryTitle, action: onSecondary)
                        alertButton(primaryTitle, action: onPrimary)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                } else {
                    alertButton(primaryTitle, action: onPrimary)
                }
            }
            .padding(20)
            .frame(maxWidth: 430)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
            .padding(.horizontal, 24)
        }
    }

    private var primaryTitle: String {
        switch alert {
        case .locationNeeded: appLocalized("Allow")
        case .confirmSOS: appLocalized("Send")
        case .paramedicOnWay, .requestSent: appLocalized("OK")
        case .confirmOthers: appLocalized("Yes")
        case .disconnectWatch: appLocalized("Disconnect")
        }
    }

    private var secondaryTitle: String? {
        switch alert {
        case .locationNeeded: appLocalized("Don't Allow")
        case .confirmSOS, .confirmOthers, .disconnectWatch: appLocalized("Cancel")
        case .paramedicOnWay, .requestSent: nil
        }
    }

    private func alertButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.gray.opacity(0.16), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct HeartRateSystemAlert: View {
    @AppStorage("appLanguage") private var appLanguage = "en"
    let dismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.22)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                Text("High Heart Rate Detected")
                    .font(.system(size: appLanguage == "ar" ? 20 : 22, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Current: 155 bpm")
                    .font(.system(size: appLanguage == "ar" ? 17 : 19))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.black, .yellow)
                        .font(.system(size: 58))
                    Spacer()
                }
                .padding(.vertical, 2)

                Text("We suggest requesting help if you are not feeling well.")
                    .font(.system(size: appLanguage == "ar" ? 17 : 18))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Button(action: dismiss) {
                    Text("OK")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .background(Color.gray.opacity(0.18), in: Capsule())
                .contentShape(Capsule())
            }
            .padding(26)
            .frame(maxWidth: 370)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
            .padding(.horizontal, 24)
        }
    }
}

private struct RequestForOthersDetailsView: View {
    @Binding var details: String
    let onSend: () -> Void
    @AppStorage("appLanguage") private var appLanguage = "en"

    var body: some View {
        NavigationStack {
            VStack(alignment: appLanguage == "ar" ? .trailing : .leading, spacing: 18) {
                Text("Emergency Description")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text("Describe the Situation")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: appLanguage == "ar" ? .trailing : .leading)

                ZStack(alignment: appLanguage == "ar" ? .topTrailing : .topLeading) {
                    TextEditor(text: $details)
                        .font(.body)
                        .multilineTextAlignment(appLanguage == "ar" ? .trailing : .leading)
                        .environment(\.layoutDirection, appLanguage == "ar" ? .rightToLeft : .leftToRight)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if details.isEmpty {
                        Text("Describe what happened in detail...")
                            .foregroundStyle(.secondary)
                            .padding(.top, 18)
                            .padding(appLanguage == "ar" ? .trailing : .leading, 16)
                            .allowsHitTesting(false)
                    }
                }
                .frame(maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.25))
                )

                Button("Send") {
                    onSend()
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.mulabbiMaroon)
                .clipShape(Capsule())
            }
            .padding(24)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

#Preview {
    HomeView(emergencyStore: CompanionEmergencyStore())
}
