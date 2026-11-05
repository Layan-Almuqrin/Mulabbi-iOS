import Foundation

struct ChatbotService {
    static let shared = ChatbotService()

    // الرابط الخاص بالشات بوت هنا
    private let chatbotURLString = ""

    func sendMessage(_ message: String) async throws -> String {
        let trimmedURL = chatbotURLString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedURL.isEmpty else {
            throw ChatbotServiceError.missingURL
        }

        guard let url = URL(string: trimmedURL) else {
            throw ChatbotServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(ChatbotRequest(message: message))

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

enum ChatbotServiceError: Error {
    case missingURL
    case invalidURL
    case serverError
    case emptyReply
}

private struct ChatbotRequest: Encodable {
    let message: String
}

private struct ChatbotResponse: Decodable {
    let reply: String
}
