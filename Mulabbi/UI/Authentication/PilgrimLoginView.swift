import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PilgrimLoginView: View {

    let onLogin: () -> Void
    let onBack: () -> Void

    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var showErrors = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    @AppStorage("appLanguage") private var appLanguage = "en"
    /// يحتفظ باسم المستخدم الذي سجل دخوله ليستخدمه الهوم والمرافقون
    @AppStorage("currentUsername") private var currentUsername = ""

    init(
        onLogin: @escaping () -> Void = {},
        onBack: @escaping () -> Void = {}
    ) {
        self.onLogin = onLogin
        self.onBack = onBack
    }

    private func tr(_ en: String, _ ar: String) -> String {
        appLanguage == "ar" ? ar : en
    }

    private var usernameError: String? {
        username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? tr("Please enter your username", "يرجى إدخال اسم المستخدم")
            : nil
    }

    private var passwordError: String? {
        password.isEmpty
            ? tr("Please enter your password", "يرجى إدخال كلمة المرور")
            : nil
    }

    private func attemptLogin() {
        showErrors = true
        errorMessage = nil

        guard usernameError == nil, passwordError == nil else {
            return
        }

        isLoading = true

        Task {
            do {
                let usernameKey = username
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()

                let snapshot = try await Firestore.firestore()
                    .collection("usernames")
                    .document(usernameKey)
                    .getDocument()

                guard let data = snapshot.data(),
                      let email = data["email"] as? String else {
                    throw LoginError.usernameNotFound
                }

                guard data["role"] as? String == "pilgrim" else {
                    throw LoginError.wrongAccountType
                }

                let result = try await Auth.auth()
                    .signIn(withEmail: email, password: password)

                guard result.user.isEmailVerified else {
                    try Auth.auth().signOut()
                    throw LoginError.emailNotVerified
                }

                await MainActor.run {
                    currentUsername = username
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    isLoading = false
                    onLogin()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = loginErrorText(for: error)
                }
            }
        }
    }

    private func loginErrorText(for error: Error) -> String {
        if let loginError = error as? LoginError {
            switch loginError {
            case .usernameNotFound:
                return tr("Username not found", "اسم المستخدم غير موجود")
            case .emailNotVerified:
                return tr(
                    "Please verify your email before logging in",
                    "يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول"
                )

            case .wrongAccountType:
                return tr(
                    "This account is registered as a paramedic",
                    "هذا الحساب مسجل كمسعف"
                )
            }
        }

        let code = AuthErrorCode(rawValue: (error as NSError).code)
        if code == .wrongPassword || code == .userNotFound ||
            code == .invalidCredential {
            return tr(
                "Username or password is incorrect",
                "اسم المستخدم أو كلمة المرور غير صحيحة"
            )
        }

        return tr(
            "Login failed. Check your connection and try again.",
            "تعذر تسجيل الدخول. تحققي من الاتصال وحاولي مرة أخرى."
        )
    }

    private enum LoginError: Error {
        case usernameNotFound
        case emailNotVerified
        case wrongAccountType
    }

    var body: some View {

        NavigationStack {

            ZStack {

                MulabbiAuthBackdrop()
                    .ignoresSafeArea()

                VStack {

                    HStack {

                        if appLanguage == "en" {

                            Button(action: {
                                onBack()
                            }) {

                                Image(systemName: "chevron.left")
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

                        } else {

                            Spacer()

                            Button(action: {
                                onBack()
                            }) {

                                Image(systemName: "chevron.right")
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
                        }
                    }
                    .environment(\.layoutDirection, .leftToRight)
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

                        VStack(alignment: .leading, spacing: 4) {

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

                            errorText(usernameError)
                        }

                        VStack(alignment: .leading, spacing: 4) {

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

                            errorText(passwordError)
                        }

                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot password?")
                                .font(.system(size: 12))
                                .foregroundColor(Color.mulabbiMaroon)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: appLanguage == "ar" ? .leading : .trailing
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(Color.mulabbiMaroon)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button(action: {
                            attemptLogin()
                        }) {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Login")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 51)
                            .background(Color.mulabbiMaroon)
                            .clipShape(Capsule())
                        }
                        .disabled(isLoading)

                        HStack(spacing: 4) {

                            Text("Don't have an account?")
                                .font(.system(size: 13))
                                .foregroundColor(.black)

                            NavigationLink(
                                destination: PilgrimSignUpView(
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

    @ViewBuilder
    private func errorText(_ message: String?) -> some View {
        if showErrors, let message {
            Text(message)
                .font(.system(size: 11))
                .foregroundColor(Color.mulabbiMaroon)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
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
    PilgrimLoginView()
}

