import SwiftUI
import UniformTypeIdentifiers
import Vision
import PDFKit
import UIKit
import FirebaseAuth
import FirebaseFirestore

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

    @State private var showErrors = false
    @State private var showFileImporter = false
    @State private var certificateURL: URL? = nil
    @State private var certificateImportError: String? = nil
    @State private var certificateConfirmed = false
    @State private var certificateLooksEligible = false
    @State private var isCheckingCertificate = false
    @State private var signupMessage: String?
    @State private var showEmailVerification = false

    init(onSignUp: @escaping () -> Void = {}) {
        self.onSignUp = onSignUp
    }

    var isArabic: Bool {
        appLanguage == "ar"
    }
    private func tr(_ en: String, _ ar: String) -> String {
        isArabic ? ar : en
    }
    private func westernDigits(_ text: String) -> String {
        text.map { character in
            character.wholeNumberValue.map { String($0) } ?? String(character)
        }.joined()
    }

    private func requiredError(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? tr("This field is required", "هذا الحقل مطلوب")
            : nil
    }

    private var usernameHasValidLength: Bool {
        (4...20).contains(username.count)
    }

    private var usernameHasValidCharacters: Bool {
        !username.isEmpty && username.allSatisfy { character in
            character.isWhitespace
            || character == "_"
            || (character.isASCII && (character.isLetter || character.isNumber))
        }
    }

    private var usernameHasLetterAndNumber: Bool {
        username.contains { $0.isASCII && $0.isLetter }
        && username.contains { $0.isASCII && $0.isNumber }
    }

    private var usernameHasNoSpaces: Bool {
        !username.isEmpty && !username.contains(where: { $0.isWhitespace })
    }

    private var isUsernameValid: Bool {
        usernameHasValidLength
        && usernameHasValidCharacters
        && usernameHasLetterAndNumber
        && usernameHasNoSpaces
    }

    private var ageError: String? {
        let digits = westernDigits(age.trimmingCharacters(in: .whitespaces))
        guard !digits.isEmpty,
              digits.allSatisfy({ $0.isASCII && $0.isNumber }),
              let value = Int(digits) else {
            return tr("Enter a valid age (numbers only)", "أدخل عمراً صحيحاً (أرقام فقط)")
        }
        return value >= 15
            ? nil
            : tr("Age must be at least 15", "يجب ألا يقل العمر عن 15")
    }

    private var firstNameError: String? {
        requiredError(firstName)
    }

    private var lastNameError: String? {
        requiredError(lastName)
    }

    private var passwordHasMinLength: Bool {
        password.count >= 8
    }

    private var passwordHasUppercase: Bool {
        password.contains { $0.isASCII && $0.isUppercase }
    }

    private var passwordHasNumber: Bool {
        password.contains { $0.isASCII && $0.isNumber }
    }

    private var passwordsMatch: Bool {
        !confirmPassword.isEmpty && confirmPassword == password
    }
    private var emailError: String? {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$"
        return trimmed.range(of: pattern, options: .regularExpression) != nil
            ? nil
            : tr("Enter a valid email address", "أدخل بريداً إلكترونياً صحيحاً")
    }

    private var certificateName: String? {
        certificateURL?.lastPathComponent
    }

    private var certificateError: String? {
        if let importError = certificateImportError {
            return importError
        }
        if certificateURL == nil { return tr("Please attach your certificate", "يرجى إرفاق الشهادة") }
        if isCheckingCertificate { return tr("Checking certificate…", "جارٍ فحص الشهادة…") }
        return certificateLooksEligible ? nil : tr("The certificate does not appear to match the required course and issuer", "الشهادة لا تبدو مطابقة للدورة والجهة المطلوبة")
    }
    private var confirmationError: String? {
        certificateConfirmed
            ? nil
            : tr("Please confirm the statement above", "يرجى تأكيد الإقرار أعلاه")
    }

    private var isFormValid: Bool {
        isUsernameValid
        && ageError == nil
        && firstNameError == nil
        && lastNameError == nil
        && passwordHasMinLength
        && passwordHasUppercase
        && passwordHasNumber
        && passwordsMatch
        && emailError == nil
        && certificateURL != nil
        && certificateLooksEligible
        && certificateConfirmed
    }
    private func validateAndSubmit() -> Bool {
        showErrors = true
        if isFormValid {
            createAccount()
            return true
        }
        return false
    }
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                let fileExtension = url.pathExtension.lowercased()
                let supportedImageExtensions: Set<String> = [
                    "png", "jpg", "jpeg", "heic", "tif", "tiff", "bmp", "gif"
                ]

                guard fileExtension == "pdf" || supportedImageExtensions.contains(fileExtension) else {
                    certificateURL = nil
                    certificateLooksEligible = false
                    certificateImportError = tr(
                        "Please choose a PDF or image file.",
                        "يرجى اختيار ملف PDF أو صورة."
                    )
                    return
                }
                if certificateURL != nil && certificateURL != url {
                    certificateConfirmed = false
                }
                certificateURL = url
                certificateImportError = nil
                certificateLooksEligible = false
                checkCertificate(url)
            }
        case .failure(let error):
            if (error as? CocoaError)?.code == .userCancelled {
                return
            }
            certificateImportError = tr(
                "Could not open the file. Please try again.",
                "تعذر فتح الملف. يرجى المحاولة مرة أخرى."
            )
        }
    }

    private func checkCertificate(_ url: URL) {
        isCheckingCertificate = true
        Task {
            let granted = url.startAccessingSecurityScopedResource()
            defer { if granted { url.stopAccessingSecurityScopedResource() } }
            do {
                var images: [UIImage] = []
                if url.pathExtension.lowercased() == "pdf", let pdf = PDFDocument(url: url) {
                    for i in 0..<min(pdf.pageCount, 3) {
                        if let page = pdf.page(at: i) { images.append(page.thumbnail(of: CGSize(width: 1800, height: 2400), for: .mediaBox)) }
                    }
                } else if let image = UIImage(contentsOfFile: url.path) { images = [image] }
                var text = ""
                for image in images {
                    guard let cgImage = image.cgImage else { continue }
                    let request = VNRecognizeTextRequest()
                    request.recognitionLevel = .accurate
                    request.recognitionLanguages = ["ar-SA", "en-US"]
                    try VNImageRequestHandler(cgImage: cgImage).perform([request])
                    text += " " + (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
                }
                let normalized = text.lowercased()
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "-", with: "")
                    .replacingOccurrences(of: "ـ", with: "")
                let course = normalized.contains("سفيرالحياة") || normalized.contains("lifeambassador")
                let firstAid = normalized.contains("الإسعافاتالأولية") || normalized.contains("الاسعافاتالاولية") || normalized.contains("firstaid")
                let issuer = normalized.contains("الهلالالأحمرالسعودي") || normalized.contains("saudiredcrescent")
                await MainActor.run {
                    certificateLooksEligible = course && firstAid && issuer
                    isCheckingCertificate = false
                }
            } catch {
                await MainActor.run { certificateLooksEligible = false; isCheckingCertificate = false }
            }
        }
    }

    private func createAccount() {
        let emailValue = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let usernameValue = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let usernameKey = usernameValue.lowercased()
        let firstNameValue = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastNameValue = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let ageValue = Int(westernDigits(age.trimmingCharacters(in: .whitespacesAndNewlines))) ?? 0
        guard let certificateURL else {
            signupMessage = tr("Please attach your certificate", "يرجى إرفاق الشهادة")
            return
        }
        let database = Firestore.firestore()
        Task {
            let hasSecurityAccess = certificateURL.startAccessingSecurityScopedResource()
            defer {
                if hasSecurityAccess {
                    certificateURL.stopAccessingSecurityScopedResource()
                }
            }
            do {
                let certificateData = try Data(contentsOf: certificateURL)
                guard certificateData.count <= 700 * 1024 else {
                    await MainActor.run {
                        signupMessage = tr(
                            "Certificate file must be 700 KB or smaller",
                            "يجب أن يكون حجم ملف الشهادة 700 كيلوبايت أو أقل"
                        )
                    }
                    return
                }
                let ref = database.collection("usernames").document(usernameKey)
                let existing = try await ref.getDocument()
                guard !existing.exists else {
                    await MainActor.run { signupMessage = tr("Username is already taken", "اسم المستخدم مستخدم بالفعل") }
                    return
                }
                let result = try await Auth.auth().createUser(withEmail: emailValue, password: password)
                do {
                    try await result.user.sendEmailVerification()
                    let userRef = database.collection("users").document(result.user.uid)
                    let certificateRef = database.collection("certificates").document(result.user.uid)
                    let contentType = UTType(filenameExtension: certificateURL.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                    let usernameData: [String: Any] = [
                        "email": emailValue,
                        "uid": result.user.uid,
                        "role": "paramedic",
                        "certificateStatus": "appears_eligible"
                    ]
                    let profileData: [String: Any] = [
                        "uid": result.user.uid,
                        "role": "paramedic",
                        "username": usernameValue,
                        "email": emailValue,
                        "age": ageValue,
                        "firstName": firstNameValue,
                        "lastName": lastNameValue,
                        "certificateFileName": certificateURL.lastPathComponent,
                        "certificateDocumentId": result.user.uid,
                        "certificateConfirmed": certificateConfirmed,
                        "certificateStatus": "appears_eligible",
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    let certificateRecord: [String: Any] = [
                        "uid": result.user.uid,
                        "fileName": certificateURL.lastPathComponent,
                        "contentType": contentType,
                        "fileBase64": certificateData.base64EncodedString(),
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    let batch = database.batch()
                    batch.setData(usernameData, forDocument: ref)
                    batch.setData(profileData, forDocument: userRef)
                    batch.setData(certificateRecord, forDocument: certificateRef)
                    try await batch.commit()
                    await MainActor.run { showEmailVerification = true }
                } catch {
                    try? await result.user.delete()
                    throw error
                }
            } catch {
                await MainActor.run { signupMessage = error.localizedDescription }
            }
        }
    }

    var body: some View {

        ZStack {

            Color.white
                .ignoresSafeArea()

            ScrollViewReader { proxy in
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
                    .id("formTop")

                    VStack(spacing: 12) {

                        Text("Create Account")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.mulabbiMaroon)

                        Text("Please enter your information")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)

                        if showErrors && !isFormValid {
                            Text(tr(
                                "*Please complete all required fields correctly to sign up",
                                "*يرجى إكمال جميع الحقول المطلوبة بشكل صحيح لإتمام التسجيل"
                            ))
                            .font(.system(size: 11))
                            .foregroundColor(Color.mulabbiMaroon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        HStack(alignment: .top, spacing: 8) {

                            VStack(alignment: .leading, spacing: 4) {

                                inputField(
                                    title: "*Username",
                                    placeholder: "Enter your username",
                                    text: $username
                                )
                                ruleRow(
                                    tr("4 to 20 characters", "من 4 إلى 20 حرفاً"),
                                    isMet: usernameHasValidLength
                                )
                                ruleRow(
                                    tr("English letters, numbers and _ only", "أحرف إنجليزية وأرقام و _ فقط"),
                                    isMet: usernameHasValidCharacters
                                )
                                ruleRow(
                                    tr("At least one letter and one number", "حرف ورقم على الأقل"),
                                    isMet: usernameHasLetterAndNumber
                                )
                                ruleRow(
                                    tr("No spaces", "بدون مسافات"),
                                    isMet: usernameHasNoSpaces
                                )
                            }
                            .frame(maxWidth: .infinity)

                            withError(ageError) {
                                inputField(
                                    title: "*Age",
                                    placeholder: "Enter your age",
                                    text: $age
                                )
                            }
                        }

                        HStack(alignment: .top, spacing: 8) {

                            withError(firstNameError) {
                                inputField(
                                    title: "*First name",
                                    placeholder: "Enter your first name",
                                    text: $firstName
                                )
                            }

                            withError(lastNameError) {
                                inputField(
                                    title: "*Last name",
                                    placeholder: "Enter your last name",
                                    text: $lastName
                                )
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {

                            passwordField(
                                title: "*Password",
                                placeholder: "Enter your password",
                                text: $password,
                                isVisible: $isPasswordVisible
                            )
                            ruleRow(
                                tr("At least 8 characters", "8 أحرف على الأقل"),
                                isMet: passwordHasMinLength
                            )
                            ruleRow(
                                tr("At least one uppercase letter", "حرف كبير واحد على الأقل"),
                                isMet: passwordHasUppercase
                            )
                            ruleRow(
                                tr("At least one number", "رقم واحد على الأقل"),
                                isMet: passwordHasNumber
                            )
                        }
                        .frame(maxWidth: .infinity)

                        VStack(alignment: .leading, spacing: 4) {

                            passwordField(
                                title: "*Confirm Password",
                                placeholder: "Enter your confirm password",
                                text: $confirmPassword,
                                isVisible: $isConfirmPasswordVisible
                            )

                            ruleRow(
                                tr("Passwords match", "كلمتا المرور متطابقتان"),
                                isMet: passwordsMatch
                            )
                        }
                        .frame(maxWidth: .infinity)

                        withError(emailError) {
                            inputField(
                                title: "*Email",
                                placeholder: "Enter your email",
                                text: $email
                            )
                        }

                        withError(certificateError) {

                            VStack(alignment: .leading, spacing: 6) {

                                Text("*Certificate")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    showFileImporter = true
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

                                        Group {
                                            if let name = certificateName {
                                                Text(name)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                                    .padding(.horizontal, 10)
                                            } else {
                                                Text("Attach Certificate")
                                            }
                                        }
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
                        }
                        withError(confirmationError) {

                            Button(action: {
                                certificateConfirmed.toggle()
                            }) {

                                HStack(alignment: .top, spacing: 8) {

                                    Image(
                                        systemName: certificateConfirmed
                                        ? "checkmark.square.fill"
                                        : "square"
                                    )
                                    .font(.system(size: 18))
                                    .foregroundColor(
                                        certificateConfirmed
                                        ? Color.mulabbiMaroon
                                        : Color.gray
                                    )

                                    Text(tr(
                                        "I confirm that this is my own Life Saver certificate.",
                                        "أقرّ بأن هذه شهادة سفير الحياة (Life Saver) الخاصة بي."
                                    ))
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                    Spacer(minLength: 0)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: {
                            if !validateAndSubmit() {
                                withAnimation {
                                    proxy.scrollTo("formTop", anchor: .top)
                                }
                            }
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
        }
        .navigationBarBackButtonHidden(true)
        .environment(
            \.layoutDirection,
            isArabic ? .rightToLeft : .leftToRight
        )
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert(
            tr("Registration", "التسجيل"),
            isPresented: Binding(
                get: { signupMessage != nil },
                set: { if !$0 { signupMessage = nil } }
            )
        ) {
            Button(tr("OK", "حسنًا")) { signupMessage = nil }
        } message: {
            Text(signupMessage ?? "")
        }
        .navigationDestination(isPresented: $showEmailVerification) {
            AuthEmailVerificationView(email: email.trimmingCharacters(in: .whitespacesAndNewlines), onVerified: onSignUp)
        }
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
    private func withError<Content: View>(
        _ message: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: 4) {

            content()

            if showErrors, let message = message {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(Color.mulabbiMaroon)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }
    private func ruleRow(_ text: String, isMet: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 10))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundColor(isMet ? Color.green : (showErrors ? Color.mulabbiMaroon : Color.gray))
        .frame(maxWidth: .infinity, alignment: .leading)
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


