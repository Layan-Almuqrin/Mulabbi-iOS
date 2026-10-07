import SwiftUI

struct ProfileData {
    var username: String
    var age: String
    var firstName: String
    var lastName: String
    var password: String
    var email: String
    var phoneCountryRegion: String
    var phoneCountryCode: String
    var phoneNumber: String
    var phoneE164: String
    var nationality: String
    var languages: Set<String>

    var fullName: String {
        "\(firstName) \(lastName)"
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static let sample = ProfileData(
        username: "Shatha77m",
        age: "20",
        firstName: "Shatha",
        lastName: "Alessa",
        password: "Shatha12345",
        email: "Shatal@gmail.com",
        phoneCountryRegion: "SA",
        phoneCountryCode: "+966",
        phoneNumber: "556786799",
        phoneE164: "+966556786799",
        nationality: "Saudi",
        languages: ["English"]
    )
}

struct MedicalRecordData {
    var bloodType: String
    var gender: String
    var chronicDiseases: String
    var medications: String
    var allergies: String
    var otherInfo: String

    static let sample = MedicalRecordData(
        bloodType: "O+",
        gender: "Female",
        chronicDiseases: "None",
        medications: "None",
        allergies: "None",
        otherInfo: "None"
    )
}

struct SettingsEditorHeader: View {
    let title: String
    let onBack: () -> Void
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        ZStack(alignment: .center) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 24, weight: .bold))
                .lineLimit(1)
                .padding(.horizontal, 58)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Button(action: onBack) {
                    Image(
                        systemName: layoutDirection == .rightToLeft
                            ? "chevron.right"
                            : "chevron.left"
                    )
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            AppColors.brandRed,
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )
                        .shadow(color: .black.opacity(0.18), radius: 3, y: 3)
                }
                .buttonStyle(.plain)

                Spacer()
            }
        }
        .frame(height: 58)
    }
}

struct SettingsValidationMessage: View {
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 16, weight: .bold))

            Text(LocalizedStringKey(text))
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(AppColors.brandRed)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsTextField: View {
    let title: String
    @Binding var text: String
    var fieldHeight: CGFloat = 52
    var isSecure = false
    var isInvalid = false
    var errorMessage: String? = nil
    var keyboardType: UIKeyboardType = .default
    var allowsOnlyDigits = false
    var maximumLength: Int? = nil

    @State private var isPasswordVisible = false
    @AppStorage("appLanguage") private var appLanguage = "en"

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 18, weight: .bold))
                .frame(
                    maxWidth: .infinity,
                    alignment: appLanguage == "ar" ? .trailing : .leading
                )
                .environment(\.layoutDirection, .leftToRight)

            HStack(spacing: 8) {
                Group {
                    if isSecure {
                        if isPasswordVisible {
                            TextField("", text: $text)
                        } else {
                            SecureField("", text: $text)
                        }
                    } else {
                        TextField("", text: $text)
                    }
                }
                .font(.system(size: 17))
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: text) { _, newValue in
                    let filtered = allowsOnlyDigits
                        ? newValue.compactMap(\.wholeNumberValue).map(String.init).joined()
                        : newValue
                    text = maximumLength.map { String(filtered.prefix($0)) } ?? filtered
                }

                if isSecure {
                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                            .font(.system(size: 18))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isPasswordVisible ? "Hide \(title)" : "Show \(title)")
                    .accessibilityValue(isPasswordVisible ? "Visible" : "Hidden")
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .padding(.horizontal, 13)
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
                    .frame(
                        maxWidth: .infinity,
                        alignment: appLanguage == "ar" ? .trailing : .leading
                    )
                    .environment(\.layoutDirection, .leftToRight)
            }
        }
    }
}

struct SettingsMenuField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var fieldHeight: CGFloat = 52
    var isInvalid = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 18, weight: .bold))

            Menu {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(LocalizedStringKey(option))
                    }
                }
            } label: {
                HStack {
                    Text(LocalizedStringKey(selection))
                        .foregroundStyle(.black)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.gray)
                }
                .font(.system(size: 17))
                .padding(.horizontal, 13)
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
            }
        }
    }
}

struct SettingsSaveButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Save")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(AppColors.brandRed, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 44)
    }
}


struct SettingsMainView: View {
    let fullName: String
    let onEditProfile: () -> Void
    let onEditMedicalRecord: () -> Void
    let onLogout: () -> Void
    
    var secondaryTitle: LocalizedStringKey = "Edit Medical Record"
    var secondaryIcon = "list.clipboard"
    var rowBorderColor: Color = AppColors.brandRed.opacity(0.75)
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                profileHeader(
                    width: geometry.size.width,
                    height: min(geometry.size.height * 0.51, 420)
                )

                VStack(spacing: 36) {
                    settingsRow(
                        title: "Edit Profile",
                        icon: "person",
                        action: onEditProfile
                    )

                    settingsRow(
                        title: secondaryTitle,
                        icon: secondaryIcon,
                        action: onEditMedicalRecord
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer(minLength: 24)

                Button(action: onLogout) {
                    HStack(spacing: 10) {
                        Text("Log Out")
                            .font(.system(size: 21, weight: .semibold))

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 22))
                            .scaleEffect(
                                x: layoutDirection == .rightToLeft ? -1 : 1,
                                y: 1
                            )
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .frame(height: 48)
                    .background(AppColors.brandRed, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.bottom, 132)
            }
        }
    }

    private func profileHeader(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color(red: 0.93, green: 0.93, blue: 0.94))
                    .frame(height: height * 0.60)

                Spacer()
            }

            Ellipse()
                .fill(Color(red: 0.93, green: 0.93, blue: 0.94))
                .frame(width: width * 1.34, height: height * 0.34)
                .position(x: width / 2, y: height * 0.59)

            VStack(spacing: 6) {
                profileAvatar(size: min(width * 0.52, 200))

                Text(LocalizedStringKey(fullName))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.black)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 2)
            }
            .position(x: width / 2, y: height * 0.69)
        }
        .frame(width: width, height: height)
    }

    private func profileAvatar(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.64, green: 0.66, blue: 0.71))

            Circle()
                .fill(.white)
                .frame(width: size * 0.33, height: size * 0.33)
                .offset(y: -size * 0.17)

            Ellipse()
                .fill(.white)
                .frame(width: size * 0.62, height: size * 0.31)
                .offset(y: size * 0.23)
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.18), radius: 3, y: 3)
    }

    private func settingsRow(
        title: LocalizedStringKey,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .regular))
                    .frame(width: 34)

                Text(title)
                    .font(.system(size: 21, weight: .semibold))

                Spacer()

                Image(
                    systemName: layoutDirection == .rightToLeft
                        ? "chevron.left"
                        : "chevron.right"
                )
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(.gray)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 17)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    rowBorderColor,
                    lineWidth: 1
                )
            }
        }
        .buttonStyle(.plain)
    }
}



struct SettingsView: View {
    @Binding var isEditing: Bool
    let onLogout: () -> Void

    @State private var route: SettingsRoute = .overview
    @State private var profile = ProfileData.sample
    @State private var medicalRecord = MedicalRecordData.sample

    init(
        isEditing: Binding<Bool> = .constant(false),
        onLogout: @escaping () -> Void = {}
    ) {
        _isEditing = isEditing
        self.onLogout = onLogout
    }

    var body: some View {
        Group {
            switch route {

            case .overview:
                SettingsMainView(
                    fullName: profile.fullName,
                    onEditProfile: {
                        open(.profile)
                    },
                    onEditMedicalRecord: {
                        open(.medicalRecord)
                    },
                    onLogout: onLogout,
                    rowBorderColor: Color.gray.opacity(0.6)
                )

            case .profile:
                EditProfileView(
                    profile: profile,
                    onBack: closeEditor,
                    onSave: { updatedProfile in
                        profile = updatedProfile
                    }
                )

            case .medicalRecord:
                EditMedicalRecordView(
                    medicalRecord: medicalRecord,
                    onBack: closeEditor,
                    onSave: { updatedRecord in
                        medicalRecord = updatedRecord
                    }
                )
            }
        }
    }

    private func open(_ destination: SettingsRoute) {
        route = destination
        isEditing = true
    }

    private func closeEditor() {
        route = .overview
        isEditing = false
    }
}



private enum SettingsRoute {
    case overview
    case profile
    case medicalRecord
}



#Preview {
    SettingsView()
}
