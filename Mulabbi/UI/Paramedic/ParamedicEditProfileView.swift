import SwiftUI
import UniformTypeIdentifiers

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

    static let sample = ParamedicProfileData(
        username: "Fahad7dd",
        age: "27",
        firstName: "Fahad",
        lastName: "Aldosari",
        password: "Fahad1234567890",
        email: "Fahad@gmail.com",
        certificateFileName: "Paramedic Certificate.pdf"
    )
}

struct ParamedicEditProfileView: View {
    let onBack: () -> Void
    let onSave: (ParamedicProfileData) -> Void

    @State private var draft: ParamedicProfileData
    @State private var confirmPassword: String
    @State private var invalidFields: Set<ParamedicProfileField> = []
    @State private var validationMessage: String?
    @State private var isImportingCertificate = false
    @State private var verifiedEmail: String
    @State private var isShowingEmailVerification = false

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
                                isInvalid: invalidFields.contains(.username)
                            )
                            .id(ParamedicProfileField.username)

                            SettingsTextField(
                                title: "Age",
                                text: $draft.age,
                                fieldHeight: 46,
                                isInvalid: invalidFields.contains(.age),
                                keyboardType: .numberPad,
                                allowsOnlyDigits: true,
                                maximumLength: 3
                            )
                            .id(ParamedicProfileField.age)
                        }
                        .environment(\.layoutDirection, .leftToRight)

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
                        .environment(\.layoutDirection, .leftToRight)

                        SettingsTextField(
                            title: "Password",
                            text: $draft.password,
                            fieldHeight: 46,
                            isSecure: true,
                            isInvalid: invalidFields.contains(.password)
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
                            keyboardType: .emailAddress
                        )
                        .id(ParamedicProfileField.email)

                        certificateField
                            .id(ParamedicProfileField.certificate)

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
        .fileImporter(
            isPresented: $isImportingCertificate,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                draft.certificateFileName = url.lastPathComponent
                invalidFields.remove(.certificate)
            }
        }
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

            Button {
                isImportingCertificate = true
            } label: {
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
                    invalidFields.contains(.certificate)
                        ? AppColors.brandRed.opacity(0.16)
                        : Color(red: 0.86, green: 0.86, blue: 0.87),
                    in: RoundedRectangle(cornerRadius: 6)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            invalidFields.contains(.certificate)
                                ? AppColors.brandRed
                                : Color.black.opacity(0.75),
                            style: StrokeStyle(lineWidth: 1.4, dash: [5, 4])
                        )
                }
            }
            .buttonStyle(.plain)

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

    private func validateAndSave(using proxy: ScrollViewProxy) {
        var invalid: Set<ParamedicProfileField> = []

        if draft.username.isBlank { invalid.insert(.username) }
        if draft.age.isBlank {
            invalid.insert(.age)
        } else if !draft.age.isValidAge {
            invalid.insert(.age)
        }
        if draft.firstName.isBlank { invalid.insert(.firstName) }
        if draft.lastName.isBlank { invalid.insert(.lastName) }
        if draft.password.isBlank { invalid.insert(.password) }
        if confirmPassword.isBlank || confirmPassword != draft.password {
            invalid.insert(.confirmPassword)
        }
        if draft.email.isBlank {
            invalid.insert(.email)
        } else if !draft.email.isValidEmail {
            invalid.insert(.email)
        }
        if draft.certificateFileName.isBlank {
            invalid.insert(.certificate)
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
                .email,
                .certificate
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
            isShowingEmailVerification = true
        } else {
            onSave(draft)
        }
    }

    private var hasBlankRequiredField: Bool {
        draft.username.isBlank
            || draft.age.isBlank
            || draft.firstName.isBlank
            || draft.lastName.isBlank
            || draft.password.isBlank
            || confirmPassword.isBlank
            || draft.email.isBlank
            || draft.certificateFileName.isBlank
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
    case certificate
}

#Preview {
    NavigationStack {
        ParamedicEditProfileView(
            profile: .sample,
            onBack: {},
            onSave: { _ in }
        )
    }
}
