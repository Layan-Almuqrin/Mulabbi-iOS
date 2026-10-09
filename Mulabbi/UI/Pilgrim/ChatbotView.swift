import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String
}

enum ChatRole {
    case assistant
    case user
}

private enum ChatbotCopy {
    static let englishWelcome =
        "Hello, I’m Mulabbi. I’m here to guide you with quick first-aid and emergency support."

    static let englishChoking =
        """
        If the person can breathe forcefully, they should continue coughing.
        However, if the person is choking and cannot speak, cry, or laugh forcefully, do the following:
        1. Stand behind the injured person.
        2. Place one foot slightly in front of the other for balance.
        3. Wrap your arms around the person’s waist.
        4. Lean the person slightly forward.
        5. Make a fist with one hand and place it above the navel.
        6. Hold the fist with your other hand, then give a quick, strong upward thrust to the abdomen.
        7. Repeat 6 to 10 abdominal thrusts until the stuck object is removed.
        If the injured person loses consciousness, perform CPR and make sure to press the Request Help button.
        """

}

struct ChatbotView: View {
    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var message = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            text: ChatbotCopy.englishWelcome
        )
    ]
    @FocusState private var isMessageFocused: Bool

    var body: some View {
        conversation
            .safeAreaInset(edge: .bottom, spacing: 0) {
                messageComposer
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
                    .background(Color(.systemBackground))
            }
    }

    private var conversation: some View {
        VStack(spacing: 0) {
            Text("Chatbot")
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 38)
                .padding(.bottom, 32)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { chatMessage in
                            switch chatMessage.role {
                            case .assistant:
                                assistantBubble(chatMessage.text)
                            case .user:
                                userBubble(chatMessage.text)
                            }
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("conversation-bottom")
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.always)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: messages.count) {
                    scrollToLatestMessage(using: proxy)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private var messageComposer: some View {
        HStack(spacing: 12) {
            if isArabic {
                sendButton
                composerTextField
            } else {
                composerTextField
                sendButton
            }
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .frame(height: 66)
        .background(.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.16), lineWidth: 1)
        }
    }

    private var composerTextField: some View {
        TextField("Ask anything...", text: $message)
            .font(.system(size: 16))
            .multilineTextAlignment(isArabic ? .trailing : .leading)
            .textInputAutocapitalization(.sentences)
            .focused($isMessageFocused)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture {
                isMessageFocused = true
            }
            .submitLabel(.send)
            .onSubmit(sendMessage)
    }

    private var sendButton: some View {
        Button(action: sendMessage) {
            Image(
                systemName: isMessageFocused
                    ? (isArabic ? "chevron.left" : "chevron.right")
                    : "chevron.up"
            )
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(AppColors.brandRed, in: Circle())
                .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Send message"))
    }

    private func assistantBubble(_ text: String) -> some View {
        HStack {
            if isArabic {
                Spacer(minLength: 18)
                assistantBubbleContent(text)
            } else {
                assistantBubbleContent(text)
                Spacer(minLength: 18)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func assistantBubbleContent(_ text: String) -> some View {
        Text(LocalizedStringKey(text))
            .font(.system(size: 13.5))
            .foregroundStyle(.black)
            .lineSpacing(2.5)
            .multilineTextAlignment(isArabic ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: isArabic ? .trailing : .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                AppColors.chatBubbleGray,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 30,
                    bottomLeadingRadius: isArabic ? 30 : 0,
                    bottomTrailingRadius: isArabic ? 0 : 30,
                    topTrailingRadius: 30,
                    style: .continuous
                )
            )
    }

    private func userBubble(_ text: String) -> some View {
        HStack {
            if isArabic {
                userBubbleContent(text)
                Spacer(minLength: 72)
            } else {
                Spacer(minLength: 72)
                userBubbleContent(text)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func userBubbleContent(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .multilineTextAlignment(isArabic ? .trailing : .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 14)
            .background(
                AppColors.brandRed,
                in: UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    bottomLeadingRadius: isArabic ? 0 : 28,
                    bottomTrailingRadius: isArabic ? 28 : 0,
                    topTrailingRadius: 28,
                    style: .continuous
                )
            )
    }

    private func sendMessage() {
        let outgoingMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !outgoingMessage.isEmpty else {
            isMessageFocused = false
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            messages.append(ChatMessage(role: .user, text: outgoingMessage))
        }

        message = ""
        isMessageFocused = false

        requestChatbotReply(for: outgoingMessage) { reply in
            withAnimation(.easeOut(duration: 0.25)) {
                messages.append(ChatMessage(role: .assistant, text: reply))
            }
        }
    }

    private func requestChatbotReply(
        for userMessage: String,
        completion: @escaping (String) -> Void
    ) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            completion(chokingInstructions)
        }
    }

    private func scrollToLatestMessage(using proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("conversation-bottom", anchor: .bottom)
            }
        }
    }

    private var chokingInstructions: String {
        ChatbotCopy.englishChoking
    }

    private var isArabic: Bool {
        appLanguage == "ar"
    }

}

#Preview("Chatbot Screen") {
    ChatbotView()
}
