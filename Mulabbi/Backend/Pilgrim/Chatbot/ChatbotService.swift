import Foundation
import FirebaseAuth

struct ChatbotService {
    static let shared = ChatbotService()

    private let chatbotURLString = "https://us-central1-mulabbi-c10b7.cloudfunctions.net/chatbot"

    func sendMessage(
        _ message: String,
        history: [ChatbotHistoryMessage]
    ) async throws -> String {
        guard let url = URL(string: chatbotURLString) else {
            throw ChatbotServiceError.invalidURL
        }

        guard let user = Auth.auth().currentUser else {
            throw ChatbotServiceError.notSignedIn
        }

        let idToken = try await user.getIDToken()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ChatbotRequest(message: message, history: history)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw ChatbotServiceError.serverError
        }

        let chatbotResponse = try JSONDecoder().decode(ChatbotResponse.self, from: data)
        let reply = chatbotResponse.reply.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !reply.isEmpty else {
            throw ChatbotServiceError.emptyReply
        }

        return reply
    }
}

struct ChatbotHistoryMessage: Encodable {
    let role: String
    let content: String
}

enum ChatbotServiceError: Error {
    case invalidURL
    case notSignedIn
    case serverError
    case emptyReply
}

private struct ChatbotRequest: Encodable {
    let message: String
    let history: [ChatbotHistoryMessage]
}

private struct ChatbotResponse: Decodable {
    let reply: String
}
