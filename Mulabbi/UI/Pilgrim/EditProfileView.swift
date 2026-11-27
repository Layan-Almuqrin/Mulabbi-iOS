import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    let onBack: () -> Void
    let onSave: (ProfileData) -> Void

    @State private var draft: ProfileData
    @State private var confirmPassword: String
    @State private var invalidFields: Set<ProfileField> = []
    @State private var additionalLanguages: Set<String>
    @State private var isAddingLanguage = false
    @State private var languageToAdd = ""
    @State private var validationMessage: String?
    @State private var emailErrorMessage: String?
    @State private var isCheckingEmail = false
    @State private var verifiedEmail: String
    @State private var isShowingEmailVerification = false
    @AppStorage("appLanguage") private var appLanguage = "en"

    private let builtInLanguages = ["Arabic", "English", "Urdu"]

    init(
        profile: ProfileData,
        onBack: @escaping () -> Void,
        onSave: @escaping (ProfileData) -> Void
    ) {
        _draft = State(initialValue: profile)
        _confirmPassword = State(initialValue: profile.password)
        _verifiedEmail = State(initialValue: profile.email.normalizedEmail)
        _additionalLanguages = State(
            initialValue: Set(
                profile.languages.filter {
                    !["Arabic", "English", "Urdu"].contains($0)
                }
            )
        )
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
                        .id(ProfileField.username)

                        SettingsTextField(
                            title: "Age",
                            text: $draft.age,
                            fieldHeight: 46,
                            isInvalid: invalidFields.contains(.age),
                            errorMessage: ageError,
                            keyboardType: .numberPad
                        )
                        .id(ProfileField.age)
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
                        .id(ProfileField.firstName)

                        SettingsTextField(
                            title: "Last name",
                            text: $draft.lastName,
                            fieldHeight: 46,
                            isInvalid: invalidFields.contains(.lastName)
                        )
                        .id(ProfileField.lastName)
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
                    .id(ProfileField.password)

                    SettingsTextField(
                        title: "Confirm Password",
                        text: $confirmPassword,
                        fieldHeight: 46,
                        isSecure: true,
                        isInvalid: invalidFields.contains(.confirmPassword),
                        errorMessage: confirmPasswordError
                    )
                    .id(ProfileField.confirmPassword)

                    SettingsTextField(
                        title: "Email",
                        text: $draft.email,
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.email),
                        errorMessage: emailErrorMessage,
                        keyboardType: .emailAddress
                    )
                    .id(ProfileField.email)
                    .onChange(of: draft.email) { _, _ in
                        emailErrorMessage = nil
                        invalidFields.remove(.email)
                    }

                    PhoneNumberField(
                        countryRegion: $draft.phoneCountryRegion,
                        countryCode: $draft.phoneCountryCode,
                        number: $draft.phoneNumber,
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.phoneNumber)
                    )
                    .id(ProfileField.phoneNumber)

                    SettingsTextField(
                        title: "Nationality",
                        text: $draft.nationality,
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.nationality)
                    )
                    .id(ProfileField.nationality)

                    languagePicker
                        .id(ProfileField.languages)

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
        .toolbar(.hidden, for: .tabBar)
        .alert("Add Language", isPresented: $isAddingLanguage) {
            TextField("Language", text: $languageToAdd)

            Button("Cancel", role: .cancel) {
                languageToAdd = ""
            }

            Button("Add") {
                addLanguage()
            }
            .disabled(languageToAdd.isBlank)
        } message: {
            Text("Enter the language you want to add.")
        }
        .overlay {
            if isShowingEmailVerification {
                EmailVerificationView(
                    email: draft.email.normalizedEmail,
                    onClose: {
                        isShowingEmailVerification = false
                    },
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

    private var languagePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Choose your language")
                .font(.system(size: 17, weight: .bold))

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 68), spacing: 8)],
                alignment: .leading,
                spacing: 8
            ) {
                ForEach(displayedLanguages, id: \.self) { language in
                    Button {
                        toggle(language)
                    } label: {
                        Text(LocalizedStringKey(language))
                            .font(.system(size: 15))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .frame(height: 36)
                            .background(
                                draft.languages.contains(language)
                                    ? Color.gray.opacity(0.82)
                                    : Color.gray.opacity(0.25),
                                in: RoundedRectangle(cornerRadius: 5)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isAddingLanguage = true
                } label: {
                    Text("+Add")
                        .font(.system(size: 15))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .frame(height: 36)
                        .background(
                            Color.gray.opacity(0.25),
                            in: RoundedRectangle(cornerRadius: 5)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(invalidFields.contains(.languages) ? 8 : 0)
        .background(
            invalidFields.contains(.languages)
                ? AppColors.brandRed.opacity(0.20)
                : Color.clear,
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay {
            if invalidFields.contains(.languages) {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(AppColors.brandRed, lineWidth: 1)
            }
        }
    }

    private var displayedLanguages: [String] {
        builtInLanguages + additionalLanguages.sorted()
    }

    private func toggle(_ language: String) {
        if draft.languages.contains(language) {
            draft.languages.remove(language)
        } else {
            draft.languages.insert(language)
        }
    }

    private func addLanguage() {
        let newLanguage = languageToAdd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newLanguage.isEmpty else { return }

        additionalLanguages.insert(newLanguage)
        draft.languages.insert(newLanguage)
        languageToAdd = ""
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
        var invalid: Set<ProfileField> = []

        draft.age = draft.age.withWesternDigits
        draft.phoneNumber = draft.phoneNumber.withWesternDigits

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
        if draft.phoneNumber.isBlank {
            invalid.insert(.phoneNumber)
        } else if let e164Number = PhoneNumberValidator.shared.e164Number(
            from: draft.phoneNumber,
            regionCode: draft.phoneCountryRegion
        ) {
            draft.phoneE164 = e164Number
        } else {
            invalid.insert(.phoneNumber)
        }
        if draft.nationality.isBlank { invalid.insert(.nationality) }
        if draft.languages.isEmpty { invalid.insert(.languages) }

        invalidFields = invalid
        validationMessage = invalid.isEmpty
            ? nil
            : hasBlankRequiredField
                ? "Please fill in all required fields"
                : "Incorrect information entered"

        guard invalid.isEmpty else {
            let fieldOrder: [ProfileField] = [
                .username,
                .age,
                .firstName,
                .lastName,
                .password,
                .confirmPassword,
                .email,
                .phoneNumber,
                .nationality,
                .languages
            ]

            if let firstInvalidField = fieldOrder.first(where: invalid.contains) {
                DispatchQueue.main.async {
                    withAnimation(.easeOut(duration: 0.25)) {
                        proxy.scrollTo(firstInvalidField, anchor: .center)
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
            || draft.phoneNumber.isBlank
            || draft.nationality.isBlank
            || draft.languages.isEmpty
    }
}

private enum ProfileField: Hashable {
    case username
    case age
    case firstName
    case lastName
    case password
    case confirmPassword
    case email
    case phoneNumber
    case nationality
    case languages
}

struct EmailVerificationView: View {
    let email: String
    let onClose: () -> Void
    let onVerified: () -> Void

    @State private var message: String?
    @State private var isChecking = false
    @State private var isSending = false
    @State private var didSendLink = false
    @State private var currentPassword = ""
    @State private var isPasswordVisible = false
    @AppStorage("appLanguage") private var appLanguage = "en"

    private var isArabic: Bool { appLanguage == "ar" }
    private func tr(_ en: String, _ ar: String) -> String { isArabic ? ar : en }

    var body: some View {
        ZStack {
            MulabbiAuthBackdrop()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: onClose) {
                        Image(systemName: isArabic ? "chevron.right" : "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.mulabbiMaroon)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 42))
                        .foregroundColor(Color.mulabbiMaroon)

                    Text(tr("Verify your new email", "تأكيد البريد الإلكتروني الجديد"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.mulabbiMaroon)

                    Text(email)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)

                    if didSendLink {
                        Text(tr(
                            "Open the email and tap the link, then return here.",
                            "افتحي رسالة البريد واضغطي الرابط، ثم عودي هنا."
                        ))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                        Button(action: checkVerification) {
                            Group {
                                if isChecking {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(tr(
                                        "I verified my email",
                                        "تم التحقق من البريد الإلكتروني"
                                    ))
                                    .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.mulabbiMaroon)
                            .clipShape(Capsule())
                        }
                        .disabled(isChecking || isSending)

                        Button(action: sendVerificationLink) {
                            Text(isSending
                                 ? tr("Sending…", "جارٍ الإرسال…")
                                 : tr("Resend verification link", "إعادة إرسال رابط التحقق"))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.mulabbiMaroon)
                        }
                        .disabled(isChecking || isSending)
                    } else {
                        Text(tr(
                            "Enter your current password before sending the link.",
                            "أدخلي كلمة المرور الحالية قبل إرسال الرابط."
                        ))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)

                        HStack(spacing: 10) {
                            Image(systemName: "lock")
                                .foregroundStyle(.gray)

                            Group {
                                if isPasswordVisible {
                                    TextField(
                                        tr("Current password", "كلمة المرور الحالية"),
                                        text: $currentPassword
                                    )
                                } else {
                                    SecureField(
                                        tr("Current password", "كلمة المرور الحالية"),
                                        text: $currentPassword
                                    )
                                }
                            }
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                    .foregroundStyle(.black)
                            }
                            .buttonStyle(.plain)
                        }
                        .environment(\.layoutDirection, .leftToRight)
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        Button(action: sendVerificationLink) {
                            Group {
                                if isSending {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(tr("Send verification link", "إرسال رابط التحقق"))
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.mulabbiMaroon)
                            .clipShape(Capsule())
                        }
                        .disabled(currentPassword.isEmpty || isSending)
                    }

                    if let message {
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundColor(Color.mulabbiMaroon)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 24)
                .frame(maxWidth: 350)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer()
            }
        }
        .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
    }

    private func sendVerificationLink() {
        Task { await sendVerificationLinkAsync() }
    }

    private func sendVerificationLinkAsync() async {
        guard !currentPassword.isEmpty else {
            message = tr("Enter your current password.", "أدخلي كلمة المرور الحالية.")
            return
        }

        guard let user = Auth.auth().currentUser,
              let currentEmail = user.email else {
            message = tr("Please log in again.", "يرجى تسجيل الدخول مرة أخرى.")
            return
        }

        isSending = true
        defer { isSending = false }

        do {
            let credential = EmailAuthProvider.credential(
                withEmail: currentEmail,
                password: currentPassword
            )
            try await user.reauthenticate(with: credential)
            Auth.auth().languageCode = isArabic ? "ar" : "en"
            try await user.sendEmailVerification(beforeUpdatingEmail: email)
            didSendLink = true
            message = tr(
                "Verification link sent. Open it, then return here.",
                "تم إرسال رابط التحقق. افتحيه ثم عودي هنا."
            )
        } catch {
            message = emailErrorText(error)
        }
    }

    private func checkVerification() {
        Task {
            isChecking = true
            defer { isChecking = false }

            do {
                let updatedUser = try await refreshedUser()

                if updatedUser.isEmailVerified,
                   updatedUser.email?.normalizedEmail == email.normalizedEmail {
                    onVerified()
                } else {
                    message = tr(
                        "Email is not verified yet. Open the link first.",
                        "لم يتم تأكيد البريد بعد. افتحي الرابط أولًا."
                    )
                }
            } catch {
                message = emailErrorText(error)
            }
        }
    }

    private func refreshedUser() async throws -> User {
        if let user = Auth.auth().currentUser {
            do {
                try await user.reload()
                if let refreshedUser = Auth.auth().currentUser {
                    return refreshedUser
                }
            } catch {
                return try await signInWithNewEmail()
            }
        }

        return try await signInWithNewEmail()
    }

    private func signInWithNewEmail() async throws -> User {
        try await Auth.auth().signIn(
            withEmail: email,
            password: currentPassword
        ).user
    }

    private func emailErrorText(_ error: Error) -> String {
        switch AuthErrorCode(rawValue: (error as NSError).code) {
        case .requiresRecentLogin:
            return tr(
                "Please log in again, then retry changing the email.",
                "يرجى تسجيل الدخول من جديد ثم إعادة محاولة تغيير البريد."
            )
        case .emailAlreadyInUse:
            return tr(
                "The email address is already in use by another account.",
                "البريد الإلكتروني مستخدم بالفعل من حساب آخر."
            )
        case .invalidEmail:
            return tr(
                "Enter a valid email address.",
                "يرجى إدخال بريد إلكتروني صحيح."
            )
        case .networkError:
            return tr(
                "Check your connection and try again.",
                "تحققي من الاتصال بالإنترنت ثم حاولي مرة أخرى."
            )
        case .tooManyRequests:
            return tr(
                "Too many attempts. Please try again later.",
                "حدثت محاولات كثيرة. حاولي مرة أخرى لاحقًا."
            )
        case .wrongPassword, .invalidCredential:
            return tr(
                didSendLink
                    ? "Open the verification link first and check your password."
                    : "The current password is incorrect.",
                didSendLink
                    ? "افتحي رابط التحقق أولًا وتأكدي من كلمة المرور."
                    : "كلمة المرور الحالية غير صحيحة."
            )
        default:
            return tr(
                "Could not verify the new email. Please try again.",
                "تعذر التحقق من البريد الجديد. حاولي مرة أخرى."
            )
        }
    }
}

struct PhoneNumberField: View {
    @Binding var countryRegion: String
    @Binding var countryCode: String
    @Binding var number: String
    var fieldHeight: CGFloat = 52
    var isInvalid = false
    var errorMessage: String? = nil

    @State private var isShowingCountryPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Phone Number")
                .font(.system(size: 18, weight: .bold))

            HStack(spacing: 0) {
                Button {
                    isShowingCountryPicker = true
                } label: {
                    HStack(spacing: 5) {
                        Text(selectedCountry.flag)
                        Text(countryCode)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.gray)
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .frame(width: 112, height: fieldHeight)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.black.opacity(0.14))
                    .frame(width: 1, height: 30)

                SettingsNumericTextField(
                    text: $number,
                    keyboardType: .phonePad,
                    placeholder: String(localized: "Phone number")
                )
                    .padding(.horizontal, 12)
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(height: fieldHeight)
            .background(
                isInvalid
                    ? AppColors.brandRed.opacity(0.28)
                    : Color(red: 0.86, green: 0.86, blue: 0.87),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        isInvalid ? AppColors.brandRed : Color.black.opacity(0.14),
                        lineWidth: 1
                    )
            }

            if let errorMessage {
                Text(LocalizedStringKey(errorMessage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.brandRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $isShowingCountryPicker) {
            CountryCodePicker(
                selectedRegion: $countryRegion,
                selectedCode: $countryCode
            )
        }
        .onChange(of: countryCode) { _, _ in
            number = String(number.prefix(maxNationalDigitCount))
        }
    }

    private var selectedCountry: CountryDialCode {
        CountryDialCode.supported.first(where: { $0.regionCode == countryRegion })
            ?? CountryDialCode.supported[0]
    }

    private var maxNationalDigitCount: Int {
        let countryCodeDigits = countryCode.filter(\.isNumber).count
        return max(1, 15 - countryCodeDigits)
    }
}

struct CountryCodePicker: View {
    @Binding var selectedRegion: String
    @Binding var selectedCode: String

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button {
                    selectedRegion = country.regionCode
                    selectedCode = country.code
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.system(size: 25))

                        Text(country.name)
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(country.code)
                            .foregroundStyle(.secondary)

                        if country.regionCode == selectedRegion {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.brandRed)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose Country")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Country or calling code")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var filteredCountries: [CountryDialCode] {
        guard !searchText.isBlank else { return CountryDialCode.supported }

        return CountryDialCode.supported.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.code.localizedCaseInsensitiveContains(searchText)
                || $0.regionCode.localizedCaseInsensitiveContains(searchText)
        }
    }
}

final class PhoneNumberValidator {
    static let shared = PhoneNumberValidator()

    let countryDialCodes: [CountryDialCode]

    private init() {
        countryDialCodes = Self.dialingCodesByRegion
            .map { CountryDialCode(regionCode: $0.key, code: $0.value) }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func e164Number(from nationalNumber: String, regionCode: String) -> String? {
        let digits = nationalNumber.filter(\.isNumber)
        guard (4...15).contains(digits.count),
              let country = countryDialCodes.first(where: { $0.regionCode == regionCode }) else {
            return nil
        }
        guard country.code.filter(\.isNumber).count + digits.count <= 15 else { return nil }
        return country.code + digits
    }

    private static let dialingCodesByRegion: [String: String] = [
        "AD": "+376", "AE": "+971", "AF": "+93", "AG": "+1268",
        "AI": "+1264", "AL": "+355", "AM": "+374", "AO": "+244",
        "AQ": "+672", "AR": "+54", "AS": "+1684", "AT": "+43",
        "AU": "+61", "AW": "+297", "AX": "+358", "AZ": "+994",
        "BA": "+387", "BB": "+1246", "BD": "+880", "BE": "+32",
        "BF": "+226", "BG": "+359", "BH": "+973", "BI": "+257",
        "BJ": "+229", "BL": "+590", "BM": "+1441", "BN": "+673",
        "BO": "+591", "BQ": "+599", "BR": "+55", "BS": "+1242",
        "BT": "+975", "BV": "+47", "BW": "+267", "BY": "+375",
        "BZ": "+501", "CA": "+1", "CC": "+61", "CD": "+243",
        "CF": "+236", "CG": "+242", "CH": "+41", "CI": "+225",
        "CK": "+682", "CL": "+56", "CM": "+237", "CN": "+86",
        "CO": "+57", "CR": "+506", "CU": "+53", "CV": "+238",
        "CW": "+599", "CX": "+61", "CY": "+357", "CZ": "+420",
        "DE": "+49", "DJ": "+253", "DK": "+45", "DM": "+1767",
        "DO": "+1809", "DZ": "+213", "EC": "+593", "EE": "+372",
        "EG": "+20", "EH": "+212", "ER": "+291", "ES": "+34",
        "ET": "+251", "FI": "+358", "FJ": "+679", "FK": "+500",
        "FM": "+691", "FO": "+298", "FR": "+33", "GA": "+241",
        "GB": "+44", "GD": "+1473", "GE": "+995", "GF": "+594",
        "GG": "+44", "GH": "+233", "GI": "+350", "GL": "+299",
        "GM": "+220", "GN": "+224", "GP": "+590", "GQ": "+240",
        "GR": "+30", "GS": "+500", "GT": "+502", "GU": "+1671",
        "GW": "+245", "GY": "+592", "HK": "+852", "HM": "+672",
        "HN": "+504", "HR": "+385", "HT": "+509", "HU": "+36",
        "ID": "+62", "IE": "+353", "IL": "+972", "IM": "+44",
        "IN": "+91", "IO": "+246", "IQ": "+964", "IR": "+98",
        "IS": "+354", "IT": "+39", "JE": "+44", "JM": "+1876",
        "JO": "+962", "JP": "+81", "KE": "+254", "KG": "+996",
        "KH": "+855", "KI": "+686", "KM": "+269", "KN": "+1869",
        "KP": "+850", "KR": "+82", "KW": "+965", "KY": "+1345",
        "KZ": "+7", "LA": "+856", "LB": "+961", "LC": "+1758",
        "LI": "+423", "LK": "+94", "LR": "+231", "LS": "+266",
        "LT": "+370", "LU": "+352", "LV": "+371", "LY": "+218",
        "MA": "+212", "MC": "+377", "MD": "+373", "ME": "+382",
        "MF": "+590", "MG": "+261", "MH": "+692", "MK": "+389",
        "ML": "+223", "MM": "+95", "MN": "+976", "MO": "+853",
        "MP": "+1670", "MQ": "+596", "MR": "+222", "MS": "+1664",
        "MT": "+356", "MU": "+230", "MV": "+960", "MW": "+265",
        "MX": "+52", "MY": "+60", "MZ": "+258", "NA": "+264",
        "NC": "+687", "NE": "+227", "NF": "+672", "NG": "+234",
        "NI": "+505", "NL": "+31", "NO": "+47", "NP": "+977",
        "NR": "+674", "NU": "+683", "NZ": "+64", "OM": "+968",
        "PA": "+507", "PE": "+51", "PF": "+689", "PG": "+675",
        "PH": "+63", "PK": "+92", "PL": "+48", "PM": "+508",
        "PN": "+64", "PR": "+1787", "PS": "+970", "PT": "+351",
        "PW": "+680", "PY": "+595", "QA": "+974", "RE": "+262",
        "RO": "+40", "RS": "+381", "RU": "+7", "RW": "+250",
        "SA": "+966", "SB": "+677", "SC": "+248", "SD": "+249",
        "SE": "+46", "SG": "+65", "SH": "+290", "SI": "+386",
        "SJ": "+47", "SK": "+421", "SL": "+232", "SM": "+378",
        "SN": "+221", "SO": "+252", "SR": "+597", "SS": "+211",
        "ST": "+239", "SV": "+503", "SX": "+1721", "SY": "+963",
        "SZ": "+268", "TC": "+1649", "TD": "+235", "TF": "+262",
        "TG": "+228", "TH": "+66", "TJ": "+992", "TK": "+690",
        "TL": "+670", "TM": "+993", "TN": "+216", "TO": "+676",
        "TR": "+90", "TT": "+1868", "TV": "+688", "TW": "+886",
        "TZ": "+255", "UA": "+380", "UG": "+256", "UM": "+1",
        "US": "+1", "UY": "+598", "UZ": "+998", "VA": "+39",
        "VC": "+1784", "VE": "+58", "VG": "+1284", "VI": "+1340",
        "VN": "+84", "VU": "+678", "WF": "+681", "WS": "+685",
        "XK": "+383", "YE": "+967", "YT": "+262", "ZA": "+27",
        "ZM": "+260", "ZW": "+263"
    ]
}

struct CountryDialCode: Identifiable {
    let regionCode: String
    let code: String

    var id: String { regionCode }

    var name: String {
        Self.nameOverrides[regionCode]
            ?? Self.englishLocale.localizedString(forRegionCode: regionCode)
            ?? regionCode
    }

    var flag: String {
        regionCode.uppercased().unicodeScalars.compactMap { scalar in
            UnicodeScalar(127397 + scalar.value).map(String.init)
        }
        .joined()
    }

    static let supported = PhoneNumberValidator.shared.countryDialCodes

    private static let englishLocale = Locale(identifier: "en_US")
    private static let nameOverrides = [
        "AC": "Ascension Island",
        "TA": "Tristan da Cunha",
        "XK": "Kosovo"
    ]
}
