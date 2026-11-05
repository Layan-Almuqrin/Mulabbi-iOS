import SwiftUI
import UIKit

struct CompanionsView: View {
    @ObservedObject var store: CompanionsStore
    @ObservedObject var emergencyStore: CompanionEmergencyStore
    let onIncomingSOS: () -> Void
    @AppStorage("currentUsername") private var currentUsername = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack {
                    HStack {
                        NavigationLink {
                            RequestsView(store: store)
                        } label: {
                            iconButton("bell")
                                .overlay(alignment: .topTrailing) {
                                    if !store.requests.isEmpty {
                                        Circle().fill(.white).frame(width: 12, height: 12)
                                            .overlay { Circle().stroke(Color.mulabbiMaroon, lineWidth: 2) }
                                            .offset(x: 4, y: -4)
                                    }
                                }
                        }

                        Spacer()
                        Text("Companions").font(.system(size: 30, weight: .bold))
                        Spacer()

                        NavigationLink {
                            SearchCompanionsView(store: store)
                        } label: {
                            iconButton("plus", size: 27)
                        }
                    }
                    .padding(.top, 12)

                    if store.companions.isEmpty {
                        Spacer()
                        EmptyState(icon: "person.2", text: "No companions available")
                        Spacer()
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                                ForEach(store.companions) { companion in
                                    /// يعرض كل مرافق ويغير حالة استلام تنبيهات الطوارئ عند الضغط على زر التفعيل  او التعطيل
                                    CompanionCard(
                                        companion: companion,
                                        onToggleAlerts: {
                                            store.toggleAlert(for: companion)
                                        }
                                    )
                                }
                            }
                            .padding(.top, 18)
                        }
                    }
                }
                .padding(.horizontal, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            store.loadAcceptedCompanions(for: currentUsername)
            store.loadIncomingRequests(for: currentUsername)
        }
    }

    private func iconButton(_ icon: String, size: CGFloat = 22) -> some View {
        Image(systemName: icon)
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(Color.mulabbiMaroon)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
    }

}

struct RequestsView: View {
    @ObservedObject var store: CompanionsStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("currentUsername") private var currentUsername = ""

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack {
                Header(title: "Requests") { dismiss() }

                if store.requests.isEmpty {
                    Spacer()
                    EmptyState(icon: "person.2", text: "No request available")
                    Spacer()
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(store.requests) { request in
                                RequestCard(
                                    request: request,
                                    onAccept: {
                                        store.accept(request)
                                        dismiss()
                                    },
                                    onReject: { store.reject(request) }
                                )
                            }
                        }
                        .padding(.top, 18)
                    }
                }
            }
            .padding(.horizontal, 28)
        }
        .toolbar(.hidden, for: .navigationBar)
        /// يحضر طلبات المرافق الخاصه بالمستخدم عند فتح الصفحه
        .onAppear {
            store.loadIncomingRequests(for: currentUsername)
        }
    }
}

private struct SearchCompanionsView: View {
    private enum SearchResult { case none, notFound, found }

    @ObservedObject var store: CompanionsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.layoutDirection) private var layoutDirection
    @AppStorage("appLanguage") private var appLanguage = "en"
    @AppStorage("currentUsername") private var currentUsername = ""
    private let companionFirebase = CompanionFirebase()
    @State private var foundCompanion: Companion?
    @State private var phoneNumber = ""
    @State private var result: SearchResult = .none
    @State private var isRequestSent = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Header(title: "Search") { dismiss() }

                HStack(spacing: 10) {
                    PhoneNumberTextField(
                        text: $phoneNumber,
                        placeholder: localizedPhonePlaceholder,
                        textAlignment: layoutDirection == .rightToLeft ? .right : .left
                    )
                        .padding(.horizontal, 14)
                        .frame(height: 48)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay { RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.25)) }

                    Button("Search") { performSearch() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 88, height: 44)
                        .background(Color.mulabbiMaroon)
                        .clipShape(Capsule())
                }
                .padding(.top, 20)

                resultView
                Spacer()
            }
            .padding(.horizontal, 22)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var resultView: some View {
        switch result {
        case .none:
            EmptyView()
        case .notFound:
            Spacer()
            EmptyState(icon: "person.2", text: "No companions found")
            Spacer()
        case .found:
            /// يعرض بطاقة بيانات المستخدم الذي تم العثور عليه في الداتابيس
            if let foundCompanion {
                /// يعرض المستخدم الذي عثر عليه ويرسل طلب اضافته كمرافق عند الضغط على زر الإضافة
                SearchResultCard(
                    companion: foundCompanion,
                    isRequestSent: $isRequestSent,
                    onAdd: {
                        sendCompanionRequest(for: foundCompanion)
                    }
                )
                .padding(.top, 25)
            }
        }
    }
    /// يبحث عن مستخدم مسجل برقم الجوال ويحدث نتيجة البحث في الواجهة.
    private func performSearch() {
        let enteredPhoneNumber = phoneNumber.filter(\.isNumber)

        guard !enteredPhoneNumber.isEmpty else {
            foundCompanion = nil
            result = .none
            return
        }

        isRequestSent = false

        companionFirebase.findPilgrim(by: enteredPhoneNumber) { searchResult in
            DispatchQueue.main.async {
                switch searchResult {
                case .success(let companion):
                    foundCompanion = companion
                    result = companion == nil ? .notFound : .found

                case .failure:
                    foundCompanion = nil
                    result = .notFound
                }
            }
        }
    }
    /// يرسل طلب إضافة المرافق الذي اختاره المستخدم.
    private func sendCompanionRequest(for companion: Companion) {
        guard !currentUsername.isEmpty else {
            return
        }

        companionFirebase.sendCompanionRequest(
            pilgrimUsername: currentUsername,
            companion: companion
        ) { requestResult in
            DispatchQueue.main.async {
                if case .success = requestResult {
                    isRequestSent = true
                }
            }
        }
    }
    private var localizedPhonePlaceholder: String {
        let bundle = Bundle.main.path(forResource: appLanguage, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? .main
        return bundle.localizedString(
            forKey: "Enter Phone number...",
            value: "Enter Phone number...",
            table: "Localizable"
        )
    }
}

private struct PhoneNumberTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let textAlignment: NSTextAlignment

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.keyboardType = .phonePad
        textField.textContentType = .telephoneNumber
        textField.font = .preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.semanticContentAttribute = .forceLeftToRight
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange), for: .editingChanged)

        DispatchQueue.main.async {
            textField.becomeFirstResponder()
        }
        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if textField.text != text {
            textField.text = text
        }
        textField.placeholder = placeholder
        textField.textAlignment = textAlignment
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding private var text: String

        init(text: Binding<String>) {
            _text = text
        }

        @objc func textDidChange(_ textField: UITextField) {
            text = textField.text ?? ""
        }
    }
}

private struct Header: View {
    let title: String
    let onBack: () -> Void
    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(Color.mulabbiMaroon)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
            Text(LocalizedStringKey(title)).font(.system(size: 26, weight: .bold))
            Spacer()
            Color.clear.frame(width: 48, height: 48)
        }
        .padding(.top, 12)
    }
}

private struct EmptyState: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: icon).font(.system(size: 64, weight: .ultraLight))
            Text(LocalizedStringKey(text)).font(.system(size: 22))
        }
    }
}

private struct SearchResultCard: View {
    let companion: Companion
    @Binding var isRequestSent: Bool
    let onAdd: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            PersonDetails(person: companion)
            Spacer(minLength: 4)
            Button(isRequestSent ? "Sent" : "Add") {
                onAdd()
            }
            .font(.caption.weight(.bold))
                .foregroundStyle(Color.mulabbiMaroon)
                .frame(width: 58, height: 38)
                .background(.white)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct CompanionCard: View {
    let companion: Companion
    let onToggleAlerts: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            PersonDetails(person: companion)
            Spacer()
            Button(action: onToggleAlerts) {
                Text(companion.isAlertEnabled ? "Enabled" : "Disabled")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        companion.isAlertEnabled ? Color.green : Color.gray
                    )
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RequestCard: View {
    let request: Companion
    let onAccept: () -> Void
    let onReject: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            RequestPersonDetails(person: request)
            Spacer(minLength: 0)
            Button("Accept", action: onAccept)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.mulabbiMaroon)
                .padding(.horizontal, 10).padding(.vertical, 9)
                .background(.white)
                .clipShape(Capsule())
            Button("Reject", action: onReject)
                .font(.caption2.weight(.bold))
                .foregroundStyle(Color.mulabbiMaroon)
                .padding(.horizontal, 10).padding(.vertical, 9)
                .background(.white)
                .clipShape(Capsule())
        }
        .padding(12)
        .background(cardGradient)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct RequestPersonDetails: View {
    let person: Companion

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 45))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Username: \(person.username)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Phone number: \(person.phoneNumber)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PersonDetails: View {
    let person: Companion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name).font(.headline.weight(.bold)).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
                Text("Username: \(person.username)").font(.caption2).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
                Text("Phone number: \(person.phoneNumber)")
                    .font(.caption2)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

private var cardGradient: LinearGradient {
    LinearGradient(colors: [Color.mulabbiMaroon, Color.mulabbiCardRose], startPoint: .leading, endPoint: .trailing)
}

#Preview {
    CompanionsView(
        store: CompanionsStore(),
        emergencyStore: CompanionEmergencyStore(),
        onIncomingSOS: { }
    )
}
