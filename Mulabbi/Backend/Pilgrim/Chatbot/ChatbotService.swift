import Foundation
import FirebaseAuth

/// مسؤول عن ارسال رسائل المساعد الذكي واستقبال الرد
struct ChatbotService {
    static let shared = ChatbotService()

    /// رابط المساعد الذكي المرفوع على السحابة
    private let chatbotURLString = "https://us-central1-mulabbi-c10b7.cloudfunctions.net/chatbot"

    /// يرسل رسالة المستخدم والمحادثة السابقة الى المساعد الذكي ثم يرجع الرد
    func sendMessage(
        _ message: String,
        history: [ChatbotHistoryMessage]
    ) async throws -> String {
        /// يتأكد ان رابط الدالة صحيح
        guard let url = URL(string: chatbotURLString) else {
            throw ChatbotServiceError.invalidURL
        }

        /// يتأكد ان المستخدم مسجل قبل ارسال الرسالة
        guard let user = Auth.auth().currentUser else {
            throw ChatbotServiceError.notSignedIn
        }

        /// يأخذ رمز الحساب عشان تتأكد الدالة من المستخدم
        let idToken = try await user.getIDToken()

        /// يجهز الرسالة والمحادثة السابقة ويرسلها للدالة السحابية
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ChatbotRequest(message: message, history: history)
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        /// يتأكد ان الرد وصل بدون مشكلة
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw ChatbotServiceError.serverError
        }

        /// يحول الرد الى نص يظهر للمستخدم
        let chatbotResponse = try JSONDecoder().decode(ChatbotResponse.self, from: data)
        let reply = chatbotResponse.reply.trimmingCharacters(in: .whitespacesAndNewlines)

        /// يتأكد ان الرد مو فاضي قبل ما يظهر للمستخدم
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

/// الاخطاء اللي ممكن تصير وقت الاتصال بالمساعد الذكي
enum ChatbotServiceError: Error {
    case invalidURL
    case notSignedIn
    case serverError
    case emptyReply
}

/// شكل البيانات اللي يرسلها التطبيق للدالة السحابية
private struct ChatbotRequest: Encodable {
    let message: String
    let history: [ChatbotHistoryMessage]
}

/// شكل الرد اللي يرجع من الدالة السحابية
private struct ChatbotResponse: Decodable {
    let reply: String
}
