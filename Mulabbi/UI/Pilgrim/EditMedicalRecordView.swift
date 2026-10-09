import SwiftUI

struct EditMedicalRecordView: View {
    let onBack: () -> Void
    let onSave: (MedicalRecordData) -> Void

    @State private var draft: MedicalRecordData
    @State private var invalidFields: Set<MedicalField> = []
    @AppStorage("appLanguage") private var appLanguage = "en"

    init(
        medicalRecord: MedicalRecordData,
        onBack: @escaping () -> Void,
        onSave: @escaping (MedicalRecordData) -> Void
    ) {
        _draft = State(initialValue: medicalRecord)
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsEditorHeader(title: "Edit Medical Record", onBack: onBack)
                .padding(.horizontal, 24)
                .padding(.top, 18)
                .padding(.bottom, 12)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                    if !invalidFields.isEmpty {
                        SettingsValidationMessage(text: "Please fill in all required fields")
                    }

                    SettingsMenuField(
                        title: "Blood type",
                        selection: $draft.bloodType,
                        options: ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"],
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.bloodType)
                    )
                    .id(MedicalField.bloodType)

                    SettingsMenuField(
                        title: "Gender",
                        selection: $draft.gender,
                        options: ["Female", "Male"],
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.gender)
                    )
                    .id(MedicalField.gender)

                    SettingsTextField(
                        title: "Chronic diseases",
                        text: $draft.chronicDiseases,
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.chronicDiseases)
                    )
                    .id(MedicalField.chronicDiseases)

                    SettingsTextField(
                        title: "Medications",
                        text: $draft.medications,
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.medications)
                    )
                    .id(MedicalField.medications)

                    SettingsTextField(
                        title: "Allergies",
                        text: $draft.allergies,
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.allergies)
                    )
                    .id(MedicalField.allergies)

                    SettingsTextField(
                        title: "Other info",
                        text: $draft.otherInfo,
                        fieldHeight: 46,
                        isInvalid: invalidFields.contains(.otherInfo)
                    )
                    .id(MedicalField.otherInfo)

                    SettingsSaveButton {
                        validateAndSave(using: proxy)
                    }
                        .padding(.top, 34)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 34)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(Color(.systemBackground))
        .toolbar(.hidden, for: .tabBar)
        .onAppear(perform: localizeDefaultValues)
        .onChange(of: appLanguage) {
            localizeDefaultValues()
        }
    }

    private func validateAndSave(using proxy: ScrollViewProxy) {
        var invalid: Set<MedicalField> = []

        if draft.bloodType.isBlank { invalid.insert(.bloodType) }
        if draft.gender.isBlank { invalid.insert(.gender) }
        if draft.chronicDiseases.isBlank { invalid.insert(.chronicDiseases) }
        if draft.medications.isBlank { invalid.insert(.medications) }
        if draft.allergies.isBlank { invalid.insert(.allergies) }
        if draft.otherInfo.isBlank { invalid.insert(.otherInfo) }

        invalidFields = invalid

        guard invalid.isEmpty else {
            let fieldOrder: [MedicalField] = [
                .bloodType,
                .gender,
                .chronicDiseases,
                .medications,
                .allergies,
                .otherInfo
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
        onSave(canonicalRecord(from: draft))
    }

    private func localizeDefaultValues() {
        let localizedNone = localizedString("None", language: appLanguage)

        if localizedNoneValues.contains(draft.chronicDiseases) {
            draft.chronicDiseases = localizedNone
        }
        if localizedNoneValues.contains(draft.medications) {
            draft.medications = localizedNone
        }
        if localizedNoneValues.contains(draft.allergies) {
            draft.allergies = localizedNone
        }
        if localizedNoneValues.contains(draft.otherInfo) {
            draft.otherInfo = localizedNone
        }
    }

    private var localizedNoneValues: Set<String> {
        [
            localizedString("None", language: "en"),
            localizedString("None", language: "ar")
        ]
    }

    private func localizedString(_ key: String, language: String) -> String {
        guard
            let localizationPath = Bundle.main.path(
                forResource: language,
                ofType: "lproj"
            ),
            let localizationBundle = Bundle(path: localizationPath)
        else {
            return key
        }

        return localizationBundle.localizedString(
            forKey: key,
            value: key,
            table: "Localizable"
        )
    }

    private func canonicalRecord(from record: MedicalRecordData) -> MedicalRecordData {
        var normalized = record

        if localizedNoneValues.contains(normalized.chronicDiseases) {
            normalized.chronicDiseases = "None"
        }
        if localizedNoneValues.contains(normalized.medications) {
            normalized.medications = "None"
        }
        if localizedNoneValues.contains(normalized.allergies) {
            normalized.allergies = "None"
        }
        if localizedNoneValues.contains(normalized.otherInfo) {
            normalized.otherInfo = "None"
        }

        return normalized
    }
}

private enum MedicalField: Hashable {
    case bloodType
    case gender
    case chronicDiseases
    case medications
    case allergies
    case otherInfo
}
