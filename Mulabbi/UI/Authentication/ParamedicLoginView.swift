import SwiftUI

struct ParamedicLoginView: View {

    @AppStorage("appLanguage") private var appLanguage = "en"

    let onLogin: () -> Void
    let onBack: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    init(
        onLogin: @escaping () -> Void = {},
        onBack: @escaping () -> Void = {}
    ) {
        self.onLogin = onLogin
        self.onBack = onBack
    }

    var body: some View {

        NavigationStack {
            ZStack {

                MulabbiAuthBackdrop()
                    .ignoresSafeArea()

                VStack {

                    HStack {

                        Button(action: {
                            onBack()
                        }) {
                            Image(systemName: "chevron.left")
                                .rotationEffect(
                                    .degrees(appLanguage == "ar" ? 180 : 0)
                                )
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.mulabbiMaroon)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 16)
                                )
                                .shadow(
                                    color: .black.opacity(0.15),
                                    radius: 4,
                                    y: 3
                                )
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 40)
                    .safeAreaPadding(.top)

                    Spacer()

                    VStack(spacing: 12) {

                        Text("Welcome")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)

                        Text("Login to your account")
                            .font(.system(size: 15))
                            .foregroundColor(.black)

                        HStack {

                            Image(systemName: "person")
                                .foregroundColor(.gray)

                            textInput(
                                "Enter your username",
                                text: $username
                            )
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)

                        HStack {

                            Image(systemName: "lock")
                                .foregroundColor(.gray)

                            textInput(
                                "Enter your password",
                                text: $password,
                                isSecure: !isPasswordVisible
                            )

                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(
                                    systemName: isPasswordVisible
                                    ? "eye"
                                    : "eye.slash"
                                )
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)

                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot password?")
                                .font(.system(size: 12))
                                .foregroundColor(Color.mulabbiMaroon)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: appLanguage == "ar" ? .leading : .trailing
                        )

                        Button(action: {
                            onLogin()
                        }) {
                            Text("Login")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 51)
                                .background(Color.mulabbiMaroon)
                                .clipShape(Capsule())
                        }

                        HStack(spacing: 4) {

                            Text("Don't have an account?")
                                .font(.system(size: 13))
                                .foregroundColor(.black)

                            NavigationLink(
                                destination: ParamedicSignUpView(
                                    onSignUp: onLogin
                                )
                            ) {
                                Text("Sign up")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(Color.mulabbiMaroon)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    .frame(width: 350)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )

                    Spacer()
                }
            }
            .environment(
                \.layoutDirection,
                appLanguage == "ar" ? .rightToLeft : .leftToRight
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func textInput(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        isSecure: Bool = false
    ) -> some View {

        ZStack(alignment: .leading) {

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16))
                    .foregroundColor(Color.gray.opacity(0.6))
                    .allowsHitTesting(false)
            }

            if isSecure {
                SecureField("", text: text)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
            } else {
                TextField("", text: text)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ParamedicLoginView()
}
