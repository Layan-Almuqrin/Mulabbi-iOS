import SwiftUI

struct ForgotPasswordView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "en"

    @State private var step = 1
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""

    var isArabic: Bool {
        appLanguage == "ar"
    }

    var body: some View {

        ZStack {

            MulabbiAuthBackdrop()
                .ignoresSafeArea()

            VStack {

                HStack {

                    Button(action: {
                        dismiss()
                    }) {

                        Image(
                            systemName: isArabic
                                ? "chevron.right"
                                : "chevron.left"
                        )
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.mulabbiMaroon)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 16)
                        )
                    }

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 40)
                .safeAreaPadding(.top)

                Spacer()

                VStack(spacing: 14) {

                    if step == 1 {

                        Text("Forgot Password")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        Text("Please enter your email registered on our system")
                            .font(.system(size: 11))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                        HStack {

                            Image(systemName: "envelope")
                                .foregroundColor(.gray)

                            textInput(
                                "Enter your Email",
                                text: $email,
                                keyboard: .emailAddress
                            )
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)

                        Button(action: {
                            step = 2
                        }) {

                            Text("Send Code")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color.mulabbiMaroon)
                                .clipShape(Capsule())
                        }

                    } else if step == 2 {

                        Text("Forgot Password")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        Text("Please enter the code sent to your email")
                            .font(.system(size: 11))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                        HStack {

                            Image(systemName: "number")
                                .foregroundColor(.gray)

                            textInput(
                                "Enter your Code",
                                text: $code,
                                keyboard: .numberPad
                            )
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)

                        HStack {

                            Text("Didn't receive the code?")
                                .font(.system(size: 9))
                                .foregroundColor(.gray)

                            Button("Resend Code") {
                            }
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(Color.mulabbiMaroon)
                        }

                        Button(action: {
                            step = 3
                        }) {

                            Text("Submit")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color.mulabbiMaroon)
                                .clipShape(Capsule())
                        }

                    } else {

                        Text("New Password")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black)

                        Text("Please enter your new password")
                            .font(.system(size: 11))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)

                        HStack {

                            Image(systemName: "lock")
                                .foregroundColor(.gray)

                            textInput(
                                "Enter your password",
                                text: $newPassword,
                                isSecure: true
                            )
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)

                        HStack {

                            Image(systemName: "lock")
                                .foregroundColor(.gray)

                            textInput(
                                "Confirm your password",
                                text: $confirmPassword,
                                isSecure: true
                            )
                        }
                        .padding(.horizontal, 12)
                        .frame(height: 42)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)

                        Button(action: {
                            dismiss()
                        }) {

                            Text("Reset Password")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                                .background(Color.mulabbiMaroon)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 22)
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
            isArabic ? .rightToLeft : .leftToRight
        )
        .navigationBarBackButtonHidden(true)
    }

    private func textInput(
        _ placeholder: LocalizedStringKey,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboard: UIKeyboardType = .default
    ) -> some View {

        ZStack(alignment: .leading) {

            if text.wrappedValue.isEmpty {
                Text(placeholder)
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray.opacity(0.6))
                    .allowsHitTesting(false)
            }

            if isSecure {
                SecureField("", text: text)
                    .font(.system(size: 12))
                    .multilineTextAlignment(.leading)
            } else {
                TextField("", text: text)
                    .font(.system(size: 12))
                    .keyboardType(keyboard)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ForgotPasswordView()
}
