//
//  ChatService.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//  Updated to call backend chatbot (Qwen VLM via phi-backend)
//

import Foundation
import Combine
import UIKit

// MARK: - Backend DTOs

struct BotImageAnalysis: Decodable {
    let incidentType: String
    let severity: String
    let incidentDescription: String

    enum CodingKeys: String, CodingKey {
        case incidentType = "incident_type"
        case severity
        case incidentDescription = "incident_description"
    }
}

struct BotChatResponse: Decodable {
    let reply: String?
    let imageAnalysis: BotImageAnalysis?
    let intent: String?
    let showReportButton: Bool?
    let reportButtonLabel: String?

    enum CodingKeys: String, CodingKey {
        case reply
        case imageAnalysis = "image_analysis"
        case intent
        case showReportButton = "show_report_button"
        case reportButtonLabel = "report_button_label"
    }
}

// MARK: - Chat models

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var images: [UIImage] = []
    var quickReplies: [String]? = nil

    var hasImages: Bool {
        !images.isEmpty
    }

    var imageCountText: String {
        if images.count == 1 {
            return "Attached 1 image"
        } else {
            return "Attached \(images.count) images"
        }
    }

    init(
        id: UUID = UUID(),
        content: String,
        isUser: Bool,
        timestamp: Date = Date(),
        images: [UIImage] = [],
        quickReplies: [String]? = nil
    ) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.images = images
        self.quickReplies = quickReplies
    }

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Chat service

@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()

    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false

    /// 백엔드 세션 유지용
    private let sessionId: String

    /// 챗봇 백엔드 베이스 URL (phi-backend)
    private let backendBaseURL: String = APIConfig.baseURL

    private var accessToken: String? {
            AuthManager.shared.token
    }

    private init() {
        self.sessionId = UUID().uuidString
        addBotWelcomeMessage()
    }

    // MARK: - Public

    func sendMessage(_ text: String, images: [UIImage] = []) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasText = !trimmed.isEmpty
        let hasImages = !images.isEmpty

        guard hasText || hasImages else { return }

        // 1) 유저 메시지 UI에 추가
        let userMessage = ChatMessage(
            content: hasText ? trimmed : (hasImages ? "Sent \(images.count) image(s)" : ""),
            isUser: true,
            images: images
        )
        messages.append(userMessage)

        // 2) 챗봇 호출
        isTyping = true
        Task {
            await generateBotResponse(for: hasText ? trimmed : "", images: images)
        }
    }

    func clearChat() {
        messages.removeAll()
        addBotWelcomeMessage()
    }

    // MARK: - Backend call

    private func generateBotResponse(for userMessage: String, images: [UIImage]) async {
        defer {
            Task { @MainActor in
                self.isTyping = false
            }
        }

        guard let url = URL(string: "\(backendBaseURL)/api/chat") else {
            appendSystemMessage("Chatbot server URL is invalid.")
            return
        }

        do {
            let request = try makeMultipartRequest(
                url: url,
                text: userMessage.isEmpty ? "Please analyze this image." : userMessage,
                images: images
            )

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                appendSystemMessage("Invalid response from chatbot server.")
                return
            }

            guard (200..<300).contains(http.statusCode) else {
                appendSystemMessage("Chatbot server error: \(http.statusCode)")
                return
            }

            let decoder = JSONDecoder()
            let botResponse = try decoder.decode(BotChatResponse.self, from: data)

            let replyText = (botResponse.reply ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let finalText: String = replyText.isEmpty
                ? "I couldn't generate a proper response."
                : replyText

            // 🔹 report 버튼 노출 여부는 show_report_button 에만 의존
            var quickReplies: [String]? = nil
            if let show = botResponse.showReportButton, show {
                let label = botResponse.reportButtonLabel ?? "Report this"
                quickReplies = [label]
            }

            let botMessage = ChatMessage(
                content: finalText,
                isUser: false,
                quickReplies: quickReplies
            )

            await MainActor.run {
                self.messages.append(botMessage)
            }

            // 필요하면 imageAnalysis를 별도 시스템 메시지로 붙이고 싶을 때 여기서 처리
            // (현재는 Python 쪽에서 reply 안에 이미 설명을 넣고 있음)
            /*
            if let analysis = botResponse.imageAnalysis {
                let analysisText = """
                [IMAGE_ANALYSIS] type=\(analysis.incidentType), severity=\(analysis.severity)
                \(analysis.incidentDescription)
                """
                let analysisMsg = ChatMessage(
                    content: analysisText,
                    isUser: false
                )
                await MainActor.run {
                    self.messages.append(analysisMsg)
                }
            }
            */

        } catch {
            appendSystemMessage("Failed to contact chatbot: \(error.localizedDescription)")
        }
    }

    /// multipart/form-data 요청 바디 생성
    private func makeMultipartRequest(url: URL, text: String, images: [UIImage]) throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // 🔑 여기 추가: JWT 토큰이 있으면 Authorization 헤더로 붙이기
        if let token = accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("🔑 [ChatService] Using access token: \(token.prefix(20))...")
        } else {
            print("⚠️ [ChatService] No access token. Authorization header will NOT be set.")
        }

        var body = Data()

        func appendField(name: String, value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        // sessionId
        appendField(name: "sessionId", value: sessionId)

        // text
        appendField(name: "text", value: text)

        // image (첫 번째만 전송)
        if let firstImage = images.first,
           let jpegData = firstImage.jpegData(compressionQuality: 0.8) {

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(jpegData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        return request
    }

    // MARK: - Helpers

    private func appendSystemMessage(_ text: String) {
        let msg = ChatMessage(content: text, isUser: false)
        messages.append(msg)
    }

    private func addBotWelcomeMessage() {
        let welcome = ChatMessage(
            content: """
            Hello! I'm the Citizen Alert chatbot. 👋

            You can:
            • Ask what incidents are happening in Hong Kong.
            • Ask how to use the app or reporting.
            • Send incident photos and I’ll help you analyze and report them.
            """,
            isUser: false
        )
        messages.append(welcome)
    }
}
