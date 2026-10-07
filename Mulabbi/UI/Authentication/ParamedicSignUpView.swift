import SwiftUI

struct ParamedicSignUpView: View {

    @AppStorage("appLanguage") private var appLanguage = "en"

    @Environment(\.dismiss) private var dismiss

    let onSignUp: () -> Void

    @State private var username = ""
    @State private var age = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var email = ""

    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    init(onSignUp: @escaping () -> Void = {}) {
        self.onSignUp = onSignUp
    }

    var isArabic: Bool {
        appLanguage == "ar"
    }

    var body: some View {

        ZStack {

            Color.white
                .ignoresSafeArea()

            ScrollView {

                VStack(spacing: 0) {

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
                    .padding(.top, 12)

                    VStack(spacing: 12) {

                        Text("Create Account")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.mulabbiMaroon)

                        Text("Please enter your information")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                        HStack(spacing: 8) {

                            inputField(
                                title: "*Username",
                                placeholder: "Enter your username",
                                text: $username
                            )

                            inputField(
                                title: "*Age",
                                placeholder: "Enter your age",
                                text: $age
                            )
                        }

                        HStack(spacing: 8) {

                            inputField(
                                title: "*First name",
                                placeholder: "Enter your first name",
                                text: $firstName
                            )

                            inputField(
                                title: "*Last name",
                                placeholder: "Enter your last name",
                                text: $lastName
                            )
                        }

                        passwordField(
                            title: "*Password",
                            placeholder: "Enter your password",
                            text: $password,
                            isVisible: $isPasswordVisible
                        )

                        passwordField(
                            title: "*Confirm Password",
                            placeholder: "Enter your confirm password",
                            text: $confirmPassword,
                            isVisible: $isConfirmPasswordVisible
                        )

                        inputField(
                            title: "*Email",
                            placeholder: "Enter your email",
                            text: $email
                        )

                        VStack(alignment: .leading, spacing: 6) {

                            Text("*Certificate")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: {
                            }) {

                                VStack(spacing: 7) {

                                    Image(systemName: "paperclip")
                                        .font(
                                            .system(
                                                size: 31,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundColor(
                                            Color.mulabbiMaroon
                                        )

                                    Text("Attach Certificate")
                                    .font(
                                        .system(
                                            size: 16,
                                            weight: .bold
                                        )
                                    )
                                    .foregroundColor(
                                        Color.mulabbiMaroon
                                    )
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 128)
                                .background(
                                    Color.gray.opacity(0.12)
                                )
                                .overlay(
                                    RoundedRectangle(
                                        cornerRadius: 6
                                    )
                                    .stroke(
                                        Color.gray,
                                        style: StrokeStyle(
                                            lineWidth: 1.4,
                                            dash: [5, 4]
                                        )
                                    )
                                )
                            }
                        }

                        Button(action: {
                            onSignUp()
                        }) {

                            Text("Create Account")
                            .font(
                                .system(
                                    size: 17,
                                    weight: .semibold
                                )
                            )
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 51)
                            .background(Color.mulabbiMaroon)
                            .clipShape(Capsule())
                        }
                        .padding(.top, 5)

                        HStack(spacing: 4) {

                            Text("Already have an account?")
                            .font(.system(size: 13))
                            .foregroundColor(.black)

                            Button("Log in") {
                                dismiss()
                            }
                            .font(
                                .system(
                                    size: 13,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(
                                Color.mulabbiMaroon
                            )
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    .frame(width: 350)
                    .background(Color.white)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 20)
                    )
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .environment(
            \.layoutDirection,
            isArabic ? .rightToLeft : .leftToRight
        )
    }

    private func inputField(
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>
    ) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack(alignment: .leading) {

                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 16))
                        .foregroundColor(Color.gray.opacity(0.6))
                        .allowsHitTesting(false)
                }

                TextField("", text: text)
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .frame(height: 46)
            .background(
                Color.gray.opacity(0.15)
            )
            .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
    }

    private func passwordField(
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        isVisible: Binding<Bool>
    ) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {

                ZStack(alignment: .leading) {

                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 16))
                            .foregroundColor(Color.gray.opacity(0.6))
                            .allowsHitTesting(false)
                    }

                    if isVisible.wrappedValue {
                        TextField("", text: text)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.leading)
                    } else {
                        SecureField("", text: text)
                            .font(.system(size: 16))
                            .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {

                    Image(
                        systemName:
                            isVisible.wrappedValue
                            ? "eye"
                            : "eye.slash"
                    )
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 46)
            .background(
                Color.gray.opacity(0.15)
            )
            .cornerRadius(6)
        }
    }
}

#Preview {
    NavigationStack {
        ParamedicSignUpView()
    }
}
