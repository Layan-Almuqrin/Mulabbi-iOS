import SwiftUI

struct CompanionsView: View {
    @ObservedObject var store: CompanionsStore
    @ObservedObject var emergencyStore: CompanionEmergencyStore
    let onIncomingSOS: () -> Void

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
                                    CompanionCard(
                                        companion: companion,
                                        onSOS: {
                                            emergencyStore.receiveSOS(from: companion)
                                            onIncomingSOS()
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
    }
}

private struct SearchCompanionsView: View {
    private enum SearchResult { case none, notFound, found }

    @ObservedObject var store: CompanionsStore
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPhoneFieldFocused: Bool
    @State private var phoneNumber = ""
    @State private var result: SearchResult = .none
    @State private var isRequestSent = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                Header(title: "Search") { dismiss() }

                HStack(spacing: 10) {
                    TextField("Enter Phone number...", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .focused($isPhoneFieldFocused)
                        .multilineTextAlignment(.trailing)
                        .environment(\.layoutDirection, .leftToRight)
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
        .onAppear { isPhoneFieldFocused = true }
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
            SearchResultCard(isRequestSent: $isRequestSent)
                .padding(.top, 25)
        }
    }

    private func performSearch() {
        result = phoneNumber.filter(\.isNumber) == "0556786799" ? .found : .notFound
        isRequestSent = false
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
            Text(text).font(.system(size: 22))
        }
    }
}

private struct SearchResultCard: View {
    @Binding var isRequestSent: Bool
    private let atheer = Companion(name: "Atheer Alhashel", username: "Atheer7", phoneNumber: "0556786799")

    var body: some View {
        HStack(spacing: 12) {
            PersonDetails(person: atheer)
            Spacer(minLength: 4)
            Button(isRequestSent ? "Sent" : "Add") { isRequestSent = true }
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
    let onSOS: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            PersonDetails(person: companion)
            Spacer()
            Button(action: onSOS) {
                Image(systemName: "exclamationmark.circle")
                    .font(.title3)
                    .foregroundStyle(.black)
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
                Text("Phone number: \(person.phoneNumber)").font(.caption2).foregroundStyle(.white).frame(maxWidth: .infinity, alignment: .leading)
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
