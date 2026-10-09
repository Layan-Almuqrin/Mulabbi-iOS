import SwiftUI

struct RoleSelectionView: View {
    @AppStorage("appLanguage") private var appLanguage = "en"

    let onSelectParamedic: () -> Void
    let onSelectPilgrim: () -> Void

    init(
        onSelectParamedic: @escaping () -> Void = {},
        onSelectPilgrim: @escaping () -> Void = {}
    ) {
        self.onSelectParamedic = onSelectParamedic
        self.onSelectPilgrim = onSelectPilgrim
    }

    var body: some View {

        ZStack {

                MulabbiAuthBackdrop()
                    .ignoresSafeArea()

                VStack {

                    HStack {

                        Button {
                            appLanguage = appLanguage == "ar" ? "en" : "ar"
                        } label: {
                            Label(
                                appLanguage == "ar" ? "EN" : "AR",
                                systemImage: "globe"
                            )
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                    .padding(.horizontal, 25)
                    .padding(.top, 30)

                    Spacer()

                    VStack(spacing: 14) {

                        Button(action: onSelectParamedic) {

                            Text("Paramedic")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    Color.mulabbiMaroon
                                )
                                .clipShape(Capsule())
                        }

                        Button(action: onSelectPilgrim) {

                            Text("Pilgrim")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 58)
                                .background(
                                    Color.mulabbiMaroon
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 35)
                }
            }
    }
}

#Preview {
    RoleSelectionView()
}
