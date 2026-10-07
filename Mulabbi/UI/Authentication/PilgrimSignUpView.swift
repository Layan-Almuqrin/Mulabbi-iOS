import SwiftUI

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
    
    init(onSignUp: @escaping () -> Void = {}) {
        self.onSignUp = onSignUp
    }
    
    private var textAlign: TextAlignment {
        .leading
    }
    
    var body: some View {
        
        ZStack {
            
            Color.white
                .ignoresSafeArea()
            
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
                    
                    
                    VStack(spacing: 12) {
                        
                        
                        Text("Sign Up")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(Color.mulabbiMaroon)
                        
                        Text("Create your account")
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
                        
                        
                        
                        inputField(
                            title: "*Phone Number",
                            placeholder: "Enter your phone number",
                            text: $phoneNumber
                        )
                        
                        
                        
                        inputField(
                            title: "*Nationality",
                            placeholder: "Enter your nationality",
                            text: $nationality
                        )
                        
                        
                        
                        Text("*Choose your language")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: 6) {
                            
                            languageButton("Arabic")
                            languageButton("English")
                            languageButton("Urdu")
                            
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
                        
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        
                        
                        Text("Medical Information")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.mulabbiMaroon)
                        
                        Text("Please provide your medical information")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        
                        
                        
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
                        
                        
                        
                        inputField(
                            title: "*Chronic diseases",
                            placeholder: "If you do not have any, enter \"None\"",
                            text: $chronicDiseases
                        )
                        
                        inputField(
                            title: "*Medications",
                            placeholder: "If you do not have any, enter \"None\"",
                            text: $medications
                        )
                        
                        inputField(
                            title: "*Allergies",
                            placeholder: "If you do not have any, enter \"None\"",
                            text: $allergies
                        )
                        
                        inputField(
                            title: "Other Info",
                            placeholder: "Other information...",
                            text: $otherInfo
                        )
                        
                        
                        
                        Button(action: {
                            onSignUp()
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
        .environment(
            \.layoutDirection,
            appLanguage == "ar" ? .rightToLeft : .leftToRight
        )
        .navigationBarBackButtonHidden(true)
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
        _ language: LocalizedStringKey
    ) -> some View {
        
        Button(language) {
        }
        .font(.system(size: 12))
        .foregroundColor(.black)
        .padding(.horizontal, 10)
        .frame(height: 46)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(6)
    }
}

#Preview {
    PilgrimSignUpView()
}
