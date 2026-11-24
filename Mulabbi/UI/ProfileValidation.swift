import Foundation

struct SettingsValidationRule {
    let title: String
    let isMet: Bool
}

extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var isValidEmail: Bool {
        let value = normalizedEmail
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    var normalizedEmail: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var isValidAge: Bool {
        let digits = trimmingCharacters(in: .whitespacesAndNewlines)
        guard digits.count <= 3,
              digits.allSatisfy({ $0.isASCII && $0.isNumber }),
              let value = Int(digits)
        else { return false }
        return value >= 15
    }

    var withWesternDigits: String {
        map { character in
            character.wholeNumberValue.map(String.init) ?? String(character)
        }
        .joined()
    }

    var hasValidSignupUsernameLength: Bool {
        (4...20).contains(count)
    }

    var hasValidSignupUsernameCharacters: Bool {
        !isEmpty && allSatisfy { character in
            character == "_"
                || (character.isASCII && (character.isLetter || character.isNumber))
        }
    }

    var hasSignupUsernameLetterAndNumber: Bool {
        contains { $0.isASCII && $0.isLetter }
            && contains { $0.isASCII && $0.isNumber }
    }

    var hasNoSignupUsernameSpaces: Bool {
        !isEmpty && !contains(where: \.isWhitespace)
    }

    var isValidSignupUsername: Bool {
        hasValidSignupUsernameLength
            && hasValidSignupUsernameCharacters
            && hasSignupUsernameLetterAndNumber
            && hasNoSignupUsernameSpaces
    }

    var hasValidSignupPasswordLength: Bool {
        count >= 8
    }

    var hasSignupPasswordUppercase: Bool {
        contains { $0.isASCII && $0.isUppercase }
    }

    var hasSignupPasswordNumber: Bool {
        contains { $0.isASCII && $0.isNumber }
    }

    var isValidSignupPassword: Bool {
        hasValidSignupPasswordLength
            && hasSignupPasswordUppercase
            && hasSignupPasswordNumber
    }

    var signupUsernameRules: [SettingsValidationRule] {
        [
            SettingsValidationRule(
                title: "4 to 20 characters",
                isMet: hasValidSignupUsernameLength
            ),
            SettingsValidationRule(
                title: "English letters, numbers and _ only",
                isMet: hasValidSignupUsernameCharacters
            ),
            SettingsValidationRule(
                title: "At least one letter and one number",
                isMet: hasSignupUsernameLetterAndNumber
            ),
            SettingsValidationRule(
                title: "No spaces",
                isMet: hasNoSignupUsernameSpaces
            )
        ]
    }

    var signupPasswordRules: [SettingsValidationRule] {
        [
            SettingsValidationRule(
                title: "At least 8 characters",
                isMet: hasValidSignupPasswordLength
            ),
            SettingsValidationRule(
                title: "At least one uppercase letter",
                isMet: hasSignupPasswordUppercase
            ),
            SettingsValidationRule(
                title: "At least one number",
                isMet: hasSignupPasswordNumber
            )
        ]
    }
}
