import Foundation
import FirebaseAuth

struct ChatbotService {
    static let shared = ChatbotService()

    /// رابط دالة المساعد الذكي المرفوعة على Firebase
    private let chatbotURLString = "https://us-central1-mulabbi-c10b7.cloudfunctions.net/chatbot"

    /// يرسل رسالة المستخدم والمحادثة السابقة الى المساعد الذكي ثم يرجع الرد
    func sendMessage(
        _ message: String,
        history: [ChatbotHistoryMessage]
    ) async throws -> String {
        guard let url = URL(string: chatbotURLString) else {
            throw ChatbotServiceError.invalidURL
        }

        /// يتأكد ان المستخدم مسجل دخوله قبل ارسال الرسالة
        guard let user = Auth.auth().currentUser else {
            throw ChatbotServiceError.notSignedIn
        }

        /// يأخذ رمز المستخدم حتى تتأكد Firebase ان الطلب من مستخدم مسجل
        let idToken = try await user.getIDToken()

        /// يجهز الطلب ويرسل الرسالة مع اخر رسائل من المحادثة
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ChatbotRequest(message: message, history: history)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        /// يتأكد ان السيرفر رجع نتيجة ناجحة
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw ChatbotServiceError.serverError
        }

        /// يحول رد السيرفر الى نص يظهر للمستخدم
        let chatbotResponse = try JSONDecoder().decode(ChatbotResponse.self, from: data)
        let reply = chatbotResponse.reply.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !reply.isEmpty else {
            throw ChatbotServiceError.emptyReply
        }

        return reply
    }
}

/// يمثل رسالة سابقة حتى يفهم المساعد الذكي تكملة المحادثة
struct ChatbotHistoryMessage: Encodable {
    let role: String
    let content: String
}

/// الاخطاء التي ممكن تحصل اثناء الاتصال بالمساعد الذكي
enum ChatbotServiceError: Error {
    case invalidURL
    case notSignedIn
    case serverError
    case emptyReply
}

/// شكل البيانات التي يرسلها التطبيق الى السيرفر
private struct ChatbotRequest: Encodable {
    let message: String
    let history: [ChatbotHistoryMessage]
}

/// شكل الرد الذي يرجع من السيرفر
private struct ChatbotResponse: Decodable {
    let reply: String
}
