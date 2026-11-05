import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PilgrimSignUpView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "en"

    let onSignUp: () -> Void

    @State private var username = ""
    @State private var age = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var email = ""
    @State private var phoneNumber = ""
    @State private var nationality = ""

    @State private var bloodType = "Choose your blood type"
    @State private var gender = ""

    @State private var chronicDiseases = ""
    @State private var medications = ""
    @State private var allergies = ""
    @State private var otherInfo = ""

    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false

    @State private var selectedLanguages: Set<String> = []
    @State private var showErrors = false
    @State private var signupMessage: String?
    @State private var showEmailVerification = false

    init(onSignUp: @escaping () -> Void = {}) {
        self.onSignUp = onSignUp
    }

    private var textAlign: TextAlignment {
        .leading
    }
    private func tr(_ en: String, _ ar: String) -> String {
        appLanguage == "ar" ? ar : en
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
    private func medicalError(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? tr("Required. Write \"None\" if you don't have any", "مطلوب. اكتب \"لا يوجد\" إذا ما عندك")
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

    private var phoneError: String? {
        let cleaned = westernDigits(phoneNumber).filter { !" -()".contains($0) }
        return cleaned.range(of: "^\\+?[0-9]{8,15}$", options: .regularExpression) != nil
            ? nil
            : tr("Enter a valid phone number, e.g. +966501234567", "أدخل رقم جوال صحيحاً، مثال: 0501234567")
    }

    private var nationalityError: String? {
        requiredError(nationality)
    }

    private var languageError: String? {
        selectedLanguages.isEmpty
            ? tr("Choose at least one language", "اختر لغة واحدة على الأقل")
            : nil
    }

    private var bloodTypeError: String? {
        bloodType == "Choose your blood type"
            ? tr("Please choose your blood type", "يرجى اختيار فصيلة الدم")
            : nil
    }

    private var genderError: String? {
        gender.isEmpty
            ? tr("Please choose your gender", "يرجى اختيار الجنس")
            : nil
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
        && phoneError == nil
        && nationalityError == nil
        && languageError == nil
        && bloodTypeError == nil
        && genderError == nil
        && medicalError(chronicDiseases) == nil
        && medicalError(medications) == nil
        && medicalError(allergies) == nil
    }
    private func validateAndSubmit() -> Bool {
        showErrors = true
        guard isFormValid else { return false }
        createAccount()
        return true
    }

    // هنا ننشئ الحساب ونحفظ بيانات الحاج بعد التأكد من الحقول.
    private func createAccount() {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let usernameValue = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let usernameKey = usernameValue.lowercased()
        let firstNameValue = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastNameValue = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phoneValue = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let nationalityValue = nationality.trimmingCharacters(in: .whitespacesAndNewlines)
        let ageValue = Int(westernDigits(age.trimmingCharacters(in: .whitespacesAndNewlines))) ?? 0
        let database = Firestore.firestore()
        Task {
            do {
                let usernameRef = database.collection("usernames").document(usernameKey)
                let existing = try await usernameRef.getDocument()
                guard !existing.exists else {
                    await MainActor.run { signupMessage = tr("Username is already taken", "اسم المستخدم مستخدم بالفعل") }
                    return
                }
                let result = try await Auth.auth().createUser(withEmail: cleanEmail, password: password)
                do {
                    try await result.user.sendEmailVerification()
                    let userRef = database.collection("users").document(result.user.uid)
                    let usernameData: [String: Any] = [
                        "email": cleanEmail,
                        "uid": result.user.uid,
                        "role": "pilgrim"
                    ]
                    let profileData: [String: Any] = [
                        "uid": result.user.uid,
                        "role": "pilgrim",
                        "username": usernameValue,
                        "email": cleanEmail,
                        "age": ageValue,
                        "firstName": firstNameValue,
                        "lastName": lastNameValue,
                        "phoneNumber": phoneValue,
                        "nationality": nationalityValue,
                        "languages": selectedLanguages.sorted(),
                        "medicalRecord": [
                            "bloodType": bloodType,
                            "gender": gender,
                            "chronicDiseases": chronicDiseases.trimmingCharacters(in: .whitespacesAndNewlines),
                            "medications": medications.trimmingCharacters(in: .whitespacesAndNewlines),
                            "allergies": allergies.trimmingCharacters(in: .whitespacesAndNewlines),
                            "otherInfo": otherInfo.trimmingCharacters(in: .whitespacesAndNewlines)
                        ],
                        "createdAt": FieldValue.serverTimestamp()
                    ]
                    let batch = database.batch()
                    batch.setData(usernameData, forDocument: usernameRef)
                    batch.setData(profileData, forDocument: userRef)
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

                        if appLanguage == "en" {

                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(Color.mulabbiMaroon)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                            }

                            Spacer()

                        } else {

                            Spacer()

                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(Color.mulabbiMaroon)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                            }
                        }
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.horizontal, 22)
                    .padding(.top, 12)
                    .id("formTop")


                    VStack(spacing: 12) {


                        Text("Sign Up")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.mulabbiMaroon)

                        Text("Create your account")
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



                        withError(phoneError) {
                            inputField(
                                title: "*Phone Number",
                                placeholder: "Enter your phone number",
                                text: $phoneNumber
                            )
                        }



                        withError(nationalityError) {
                            inputField(
                                title: "*Nationality",
                                placeholder: "Enter your nationality",
                                text: $nationality
                            )
                        }



                        withError(languageError) {
                            VStack(spacing: 12) {

                                Text("*Choose your language")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                HStack(spacing: 6) {

                                    languageButton("Arabic", value: "Arabic")
                                    languageButton("English", value: "English")
                                    languageButton("Urdu", value: "Urdu")

                                    Button("+ Add") {
                                    }
                                    .font(.system(size: 12))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 10)
                                    .frame(height: 46)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(6)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }


                        Divider()
                            .padding(.vertical, 8)



                        Text("Medical Information")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.mulabbiMaroon)

                        Text("Please provide your medical information")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)



                        withError(bloodTypeError) {
                            dropdownField(
                                title: "*Blood type",
                                selectedText: bloodType == "Choose your blood type"
                                    ? "Choose your blood type"
                                    : bloodType
                            ) {
                                ForEach(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"], id: \.self) { type in
                                    Button(type) {
                                        bloodType = type
                                    }
                                }
                            }
                        }



                        withError(genderError) {
                            dropdownField(
                                title: "*Gender",
                                selectedText: gender.isEmpty
                                    ? "Choose your gender"
                                    : gender
                            ) {
                                Button("Female") {
                                    gender = "Female"
                                }
                                Button("Male") {
                                    gender = "Male"
                                }
                            }
                        }



                        withError(medicalError(chronicDiseases)) {
                            inputField(
                                title: "*Chronic diseases",
                                placeholder: "If you do not have any, enter \"None\"",
                                text: $chronicDiseases
                            )
                        }

                        withError(medicalError(medications)) {
                            inputField(
                                title: "*Medications",
                                placeholder: "If you do not have any, enter \"None\"",
                                text: $medications
                            )
                        }

                        withError(medicalError(allergies)) {
                            inputField(
                                title: "*Allergies",
                                placeholder: "If you do not have any, enter \"None\"",
                                text: $allergies
                            )
                        }

                        inputField(
                            title: "Other Info",
                            placeholder: "Other information...",
                            text: $otherInfo
                        )



                        Button(action: {
                            if !validateAndSubmit() {
                                withAnimation {
                                    proxy.scrollTo("formTop", anchor: .top)
                                }
                            }
                        }) {
                            Text("Sign Up")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 51)
                                .background(Color.mulabbiMaroon)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 8)



                        HStack(spacing: 4) {

                            Text("Already have an account?")
                                .font(.system(size: 13))
                                .foregroundColor(.black)

                            Button("Log in") {
                                dismiss()
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.mulabbiMaroon)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 20)
                    .frame(width: 350)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
            }
        }
        .environment(
            \.layoutDirection,
            appLanguage == "ar" ? .rightToLeft : .leftToRight
        )
        .navigationBarBackButtonHidden(true)
        .alert(tr("Registration", "التسجيل"), isPresented: Binding(get: { signupMessage != nil }, set: { if !$0 { signupMessage = nil } })) {
            Button(tr("OK", "حسنًا")) { signupMessage = nil }
        } message: { Text(signupMessage ?? "") }
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
                    .multilineTextAlignment(textAlign)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
                .frame(height: 46)
                .background(Color.gray.opacity(0.15))
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
                            .multilineTextAlignment(textAlign)
                    } else {
                        SecureField("", text: text)
                            .font(.system(size: 16))
                            .multilineTextAlignment(textAlign)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(systemName: isVisible.wrappedValue ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(height: 46)
            .background(Color.gray.opacity(0.15))
            .cornerRadius(6)
        }
    }



    private func dropdownField<Content: View>(
        title: LocalizedStringKey,
        selectedText: String,
        @ViewBuilder options: () -> Content
    ) -> some View {

        VStack(alignment: .leading, spacing: 6) {

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                options()
            } label: {
                HStack(spacing: 8) {

                    Text(LocalizedStringKey(selectedText))
                        .font(.system(size: 16))
                        .foregroundColor(.gray)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(6)
            }
            .frame(maxWidth: .infinity)
        }
    }



    private func languageButton(
        _ language: LocalizedStringKey,
        value: String
    ) -> some View {

        Button(language) {
            if selectedLanguages.contains(value) {
                selectedLanguages.remove(value)
            } else {
                selectedLanguages.insert(value)
            }
        }
        .font(.system(size: 12))
        .foregroundColor(.black)
        .padding(.horizontal, 10)
        .frame(height: 46)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    Color.mulabbiMaroon,
                    lineWidth: selectedLanguages.contains(value) ? 1.5 : 0
                )
        )
    }
}



struct PilgrimEmailVerificationView: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage = "en"

    let email: String
    let onVerified: () -> Void

    @State private var code = ""
    @State private var message: String? = nil
    private let skipCodeCheckForTesting = false

    private var isArabic: Bool {
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
    private func verify() {
        guard code.count == 6 else {
            message = tr("Enter the 6-digit code", "أدخل الرمز المكوّن من 6 أرقام")
            return
        }
        message = nil
        if skipCodeCheckForTesting {
            onVerified()
        }
    }

    var body: some View {

        ZStack {

            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {

                HStack {

                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: isArabic ? "chevron.right" : "chevron.left")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Color.mulabbiMaroon)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                    }

                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)


                VStack(spacing: 12) {

                    Text(tr("Verify Email", "تأكيد البريد الإلكتروني"))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color.mulabbiMaroon)

                    Text(tr(
                        "Enter the 6-digit verification code for",
                        "أدخل رمز التحقق المكوّن من 6 أرقام الخاص بـ"
                    ))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                    Text(email)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.black)


                    ZStack {
                        if code.isEmpty {
                            Text(tr("Enter the 6-digit code", "أدخل رمز التحقق"))
                                .font(.system(size: 16))
                                .foregroundColor(Color.gray.opacity(0.6))
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $code)
                            .font(.system(size: 16))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 46)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(6)
                    .onChange(of: code) { _, newValue in
                        let digits = String(
                            westernDigits(newValue)
                                .filter { $0.isASCII && $0.isNumber }
                                .prefix(6)
                        )
                        if digits != newValue {
                            code = digits
                        }
                    }

                    if let message = message {
                        Text(message)
                            .font(.system(size: 11))
                            .foregroundColor(Color.mulabbiMaroon)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button(action: {
                        verify()
                    }) {
                        Text(tr("Verify", "تأكيد"))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 51)
                            .background(Color.mulabbiMaroon)
                            .clipShape(Capsule())
                    }
                    .padding(.top, 8)

                    HStack(spacing: 4) {

                        Text(tr("Didn't receive the code?", "لم يصلك الرمز؟"))
                            .font(.system(size: 13))
                            .foregroundColor(.black)

                        Button(tr("Resend Code", "إعادة إرسال الرمز")) {
                        }
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.mulabbiMaroon)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
                .frame(width: 350)
                .padding(.top, 20)

                Spacer()
            }
        }
        .environment(
            \.layoutDirection,
            isArabic ? .rightToLeft : .leftToRight
        )
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PilgrimSignUpView()
}

