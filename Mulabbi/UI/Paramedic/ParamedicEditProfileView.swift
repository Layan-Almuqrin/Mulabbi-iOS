import SwiftUI

struct ParamedicProfileData {
    var username: String
    var age: String
    var firstName: String
    var lastName: String
    var password: String
    var email: String
    var certificateFileName: String

    var fullName: String {
        "\(firstName) \(lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let empty = ParamedicProfileData(
        username: "",
        age: "",
        firstName: "",
        lastName: "",
        password: "",
        email: "",
        certificateFileName: ""
    )
}

struct ParamedicEditProfileView: View {
    let onBack: () -> Void
    let onSave: (ParamedicProfileData) -> Void

    @State private var draft: ParamedicProfileData
    @State private var confirmPassword: String
    @State private var invalidFields: Set<ParamedicProfileField> = []
    @State private var validationMessage: String?
    @State private var emailErrorMessage: String?
    @State private var isCheckingEmail = false
    @State private var verifiedEmail: String
    @State private var isShowingEmailVerification = false
    @AppStorage("appLanguage") private var appLanguage = "en"

    init(
        profile: ParamedicProfileData,
        onBack: @escaping () -> Void,
        onSave: @escaping (ParamedicProfileData) -> Void
    ) {
        _draft = State(initialValue: profile)
        _confirmPassword = State(initialValue: profile.password)
        _verifiedEmail = State(initialValue: profile.email.normalizedEmail)
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsEditorHeader(title: "Edit Profile", onBack: onBack)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 10)

            if let validationMessage {
                SettingsValidationMessage(text: validationMessage)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 6)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        HStack(alignment: .top, spacing: 10) {
                            SettingsTextField(
                                title: "Username",
                                text: $draft.username,
                                fieldHeight: 46,
                                isInvalid: invalidFields.contains(.username),
                                validationRules: invalidFields.contains(.username)
                                    ? draft.username.signupUsernameRules
                                    : []
                            )
                            .id(ParamedicProfileField.username)

                            SettingsTextField(
                                title: "Age",
                                text: $draft.age,
                                fieldHeight: 46,
                                isInvalid: invalidFields.contains(.age),
                                errorMessage: ageError,
                                keyboardType: .numberPad
                            )
                            .id(ParamedicProfileField.age)
                        }
                        .environment(
                            \.layoutDirection,
                            appLanguage == "ar" ? .rightToLeft : .leftToRight
                        )

                        HStack(alignment: .top, spacing: 10) {
                            SettingsTextField(
                                title: "First name",
                                text: $draft.firstName,
                                fieldHeight: 46,
                                isInvalid: invalidFields.contains(.firstName)
                            )
                            .id(ParamedicProfileField.firstName)

                            SettingsTextField(
                                title: "Last name",
                                text: $draft.lastName,
                                fieldHeight: 46,
                                isInvalid: invalidFields.contains(.lastName)
                            )
                            .id(ParamedicProfileField.lastName)
                        }
                        .environment(
                            \.layoutDirection,
                            appLanguage == "ar" ? .rightToLeft : .leftToRight
                        )

                        SettingsTextField(
                            title: "Password",
                            text: $draft.password,
                            fieldHeight: 46,
                            isSecure: true,
                            isInvalid: invalidFields.contains(.password),
                            validationRules: invalidFields.contains(.password)
                                ? draft.password.signupPasswordRules
                                : []
                        )
                        .id(ParamedicProfileField.password)

                        SettingsTextField(
                            title: "Confirm Password",
                            text: $confirmPassword,
                            fieldHeight: 46,
                            isSecure: true,
                            isInvalid: invalidFields.contains(.confirmPassword),
                            errorMessage: confirmPasswordError
                        )
                        .id(ParamedicProfileField.confirmPassword)

                        SettingsTextField(
                            title: "Email",
                            text: $draft.email,
                            fieldHeight: 46,
                            isInvalid: invalidFields.contains(.email),
                            errorMessage: emailErrorMessage,
                            keyboardType: .emailAddress
                        )
                        .id(ParamedicProfileField.email)
                        .onChange(of: draft.email) { _, _ in
                            emailErrorMessage = nil
                            invalidFields.remove(.email)
                        }

                        certificateField

                        SettingsSaveButton {
                            validateAndSave(using: proxy)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 34)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .overlay {
            if isShowingEmailVerification {
                EmailVerificationView(
                    email: draft.email.normalizedEmail,
                    onClose: { isShowingEmailVerification = false },
                    onVerified: {
                        verifiedEmail = draft.email.normalizedEmail
                        isShowingEmailVerification = false
                        onSave(draft)
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isShowingEmailVerification)
    }

    private var certificateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Certificate")
                .font(.system(size: 18, weight: .bold))

            VStack(spacing: 7) {
                Image(systemName: "paperclip")
                    .font(.system(size: 31, weight: .semibold))

                Text("Attach Certificate")
                    .font(.system(size: 16, weight: .bold))

                if !draft.certificateFileName.isBlank {
                    Text(draft.certificateFileName)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .foregroundStyle(AppColors.brandRed)
            .frame(maxWidth: .infinity)
            .frame(height: 128)
            .background(
                Color(red: 0.86, green: 0.86, blue: 0.87),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        Color.black.opacity(0.75),
                        style: StrokeStyle(lineWidth: 1.4, dash: [5, 4])
                    )
            }
        }
    }

    private var confirmPasswordError: String? {
        guard
            invalidFields.contains(.confirmPassword),
            !confirmPassword.isBlank,
            confirmPassword != draft.password
        else { return nil }

        return "Passwords do not match"
    }

    private var ageError: String? {
        guard invalidFields.contains(.age),
              let age = Int(draft.age),
              age < 15
        else { return nil }

        return "Age must be at least 15"
    }

    private func validateAndSave(using proxy: ScrollViewProxy) {
        var invalid: Set<ParamedicProfileField> = []

        draft.age = draft.age.withWesternDigits

        if !draft.username.isValidSignupUsername { invalid.insert(.username) }
        if draft.age.isBlank {
            invalid.insert(.age)
        } else if !draft.age.isValidAge {
            invalid.insert(.age)
        }
        if draft.firstName.isBlank { invalid.insert(.firstName) }
        if draft.lastName.isBlank { invalid.insert(.lastName) }
        if !draft.password.isBlank {
            if !draft.password.isValidSignupPassword {
                invalid.insert(.password)
            }
            if confirmPassword != draft.password {
                invalid.insert(.confirmPassword)
            }
        } else if !confirmPassword.isBlank {
            invalid.insert(.confirmPassword)
        }
        if draft.email.isBlank {
            invalid.insert(.email)
        } else if !draft.email.isValidEmail {
            invalid.insert(.email)
        }
        invalidFields = invalid
        validationMessage = invalid.isEmpty
            ? nil
            : hasBlankRequiredField
                ? "Please fill in all required fields"
                : "Incorrect information entered"

        guard invalid.isEmpty else {
            let order: [ParamedicProfileField] = [
                .username,
                .age,
                .firstName,
                .lastName,
                .password,
                .confirmPassword,
                .email
            ]

            if let firstInvalid = order.first(where: invalid.contains) {
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(firstInvalid, anchor: .center)
                    }
                }
            }
            return
        }

        if draft.email.normalizedEmail != verifiedEmail {
            checkEmailAvailability()
        } else {
            onSave(draft)
        }
    }

    private func checkEmailAvailability() {
        guard !isCheckingEmail else { return }
        isCheckingEmail = true

        Task {
            defer { isCheckingEmail = false }

            do {
                let isAvailable = try await ProfileEmailAvailability.isAvailable(
                    draft.email.normalizedEmail
                )

                guard isAvailable else {
                    invalidFields.insert(.email)
                    emailErrorMessage = "The email address is already in use by another account."
                    validationMessage = "Incorrect information entered"
                    return
                }

                emailErrorMessage = nil
                isShowingEmailVerification = true
            } catch {
                invalidFields.insert(.email)
                emailErrorMessage = "Could not check whether this email is available. Please try again."
                validationMessage = "Incorrect information entered"
            }
        }
    }

    private var hasBlankRequiredField: Bool {
        draft.username.isBlank
            || draft.age.isBlank
            || draft.firstName.isBlank
            || draft.lastName.isBlank
            || draft.email.isBlank
    }
}

private enum ParamedicProfileField: Hashable {
    case username
    case age
    case firstName
    case lastName
    case password
    case confirmPassword
    case email
}

#Preview {
    NavigationStack {
        ParamedicEditProfileView(
            profile: .empty,
            onBack: {},
            onSave: { _ in }
        )
    }
}
