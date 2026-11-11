import SwiftUI

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let text: String
    let shouldLocalize: Bool

    init(role: ChatRole, text: String, shouldLocalize: Bool = false) {
        self.role = role
        self.text = text
        self.shouldLocalize = shouldLocalize
    }
}

enum ChatRole {
    case assistant
    case user
}

private enum ChatbotCopy {
    static let englishWelcome =
        "Hello, I’m Mulabbi. I’m here to guide you with quick first-aid and emergency support."
}

struct ChatbotView: View {
    @AppStorage("appLanguage") private var appLanguage = "en"
    @State private var message = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            role: .assistant,
            text: ChatbotCopy.englishWelcome,
            shouldLocalize: true
        )
    ]
    @State private var isWaitingForReply = false
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
                                assistantBubble(chatMessage)
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

    private func assistantBubble(_ message: ChatMessage) -> some View {
        HStack {
            if isArabic {
                Spacer(minLength: 18)
                assistantBubbleContent(message)
            } else {
                assistantBubbleContent(message)
                Spacer(minLength: 18)
            }
        }
        .environment(\.layoutDirection, .leftToRight)
    }

    private func assistantBubbleContent(_ message: ChatMessage) -> some View {
        Group {
            if message.shouldLocalize {
                Text(LocalizedStringKey(message.text))
            } else {
                Text(message.text)
            }
        }
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

        guard !outgoingMessage.isEmpty, !isWaitingForReply else {
            isMessageFocused = false
            return
        }

        let conversationHistory = messages
            .filter { !$0.shouldLocalize }
            .suffix(8)
            .map { chatMessage in
                let role: String

                switch chatMessage.role {
                case .assistant:
                    role = "assistant"
                case .user:
                    role = "user"
                }

                return ChatbotHistoryMessage(role: role, content: chatMessage.text)
            }

        withAnimation(.easeOut(duration: 0.2)) {
            messages.append(ChatMessage(role: .user, text: outgoingMessage))
        }

        message = ""
        isMessageFocused = false
        isWaitingForReply = true

        Task {
            do {
                let reply = try await ChatbotService.shared.sendMessage(
                    outgoingMessage,
                    history: conversationHistory
                )

                withAnimation(.easeOut(duration: 0.25)) {
                    messages.append(ChatMessage(role: .assistant, text: reply))
                }
            } catch {
                withAnimation(.easeOut(duration: 0.25)) {
                    messages.append(
                        ChatMessage(role: .assistant, text: chatbotErrorMessage)
                    )
                }
            }

            isWaitingForReply = false
        }
    }

    private var chatbotErrorMessage: String {
        isArabic
            ? "تعذر الحصول على رد. حاول مرة أخرى."
            : "Couldn’t get a response. Please try again."
    }

    private func scrollToLatestMessage(using proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo("conversation-bottom", anchor: .bottom)
            }
        }
    }

    private var isArabic: Bool {
        appLanguage == "ar"
    }

}
