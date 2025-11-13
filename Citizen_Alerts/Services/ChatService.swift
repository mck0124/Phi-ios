//
//  ChatService.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import Foundation
import Combine
import UIKit

/// 채팅 메시지
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var messageType: MessageType
    var images: [UIImage] = []
    var quickReplies: [String]?
    var alertCard: ChatAlertCard?
    
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
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date(), messageType: MessageType = .text, images: [UIImage] = [], quickReplies: [String]? = nil, alertCard: ChatAlertCard? = nil) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.messageType = messageType
        self.images = images
        self.quickReplies = quickReplies
        self.alertCard = alertCard
    }
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}

struct ChatAlertCard: Equatable {
    let title: String
    let location: String
    let description: String
    let severity: String
}

enum MessageType {
    case text
    case quickReply
    case alertCard
}

/// 챗봇 서비스
@MainActor
class ChatService: ObservableObject {
    static let shared = ChatService()
    
    @Published var messages: [ChatMessage] = []
    @Published var isTyping = false
    
    private init() {
        addBotWelcomeMessage()
    }
    
    /// 사용자 메시지 전송
    func sendMessage(_ text: String, images: [UIImage] = []) {
        let userMessage = ChatMessage(content: text, isUser: true, images: images)
        messages.append(userMessage)
        
        // 챗봇 응답
        isTyping = true
        Task {
            await generateBotResponse(for: text, images: images)
        }
    }
    
    /// 챗봇 응답 생성
    private func generateBotResponse(for userMessage: String, images: [UIImage]) async {
        // 간단한 지연 (타이핑 효과)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let lowercased = userMessage.lowercased()
        
        // 이미지가 있고 특정 키워드가 있으면 경고 카드 생성
        if !images.isEmpty && (lowercased.contains("knife") || lowercased.contains("knife") || lowercased.contains("danger") || lowercased.contains("emergency") || lowercased.contains("attack") || lowercased.contains("naked") || lowercased.contains("running")) {
            // 경고 카드와 함께 응답
            let alertTitle = extractAlertTitle(from: userMessage)
            let location = extractLocation(from: userMessage) ?? "Central, Hong Kong"
            
            let alertCard = ChatAlertCard(
                title: alertTitle,
                location: location,
                description: userMessage,
                severity: "High"
            )
            
            let response = alertTitle
            let quickReplies = ["Did I get it right?", "Need more info"]
            
            isTyping = false
            let botMessage = ChatMessage(
                content: response,
                isUser: false,
                quickReplies: quickReplies,
                alertCard: alertCard
            )
            messages.append(botMessage)
            return
        }
        
        var response = ""
        var quickReplies: [String]? = nil
        
        // 키워드 기반 응답
        if lowercased.contains("도움말") || lowercased.contains("help") {
            response = """
            Hello! I'm the Citizen Alert chatbot. How can I help you?
            
            Available commands:
            • "report" - Reporting guide
            • "alerts" - View recent alerts
            • "help" - Help guide
            • "nearby" - View alerts near you
            """
        } else if lowercased.contains("신고") || lowercased.contains("report") {
            response = """
            How to report:
            
            1. Tap the 'Report' tab at the bottom
            2. Select incident type (fire, traffic, emergency, etc.)
            3. Choose location (auto or manual)
            4. Add photos and description
            5. Submit your report
            
            For emergencies, call 999 directly!
            """
        } else if lowercased.contains("알림") || lowercased.contains("alerts") {
            response = """
            To view recent alerts:
            
            • Map tab - View alerts on map
            • Alerts tab - View as list
            • Filter to see specific types
            
            Auto-alert settings can be changed in Settings.
            """
        } else if lowercased.contains("급") || lowercased.contains("emergency") {
            response = """
            ⚠️ Emergency Report
            
            For urgent situations, call immediately:
            
            🚨 999 (Fire, Medical)
            🚨 999 (Police)
            
            Also report in the app to alert people nearby.
            """
        } else if lowercased.contains("what") && lowercased.contains("happen") {
            response = "I can help you check recent incidents. Try asking about specific locations or types of alerts."
            quickReplies = ["Show nearby alerts", "Report an incident"]
        } else if lowercased.contains("감사") || lowercased.contains("고마워") || lowercased.contains("thanks") {
            response = "You're welcome! Feel free to ask if you need more help. 😊"
        } else {
            // 기본 응답
            response = """
            I'm sorry, I didn't understand that. 😅
            
            Try these commands:
            • "help" - Usage guide
            • "report" - Reporting guide
            • "alerts" - How to view alerts
            
            Feel free to ask other questions!
            """
        }
        
        isTyping = false
        
        let botMessage = ChatMessage(content: response, isUser: false, quickReplies: quickReplies)
        messages.append(botMessage)
    }
    
    // MARK: - Helper Functions
    private func extractAlertTitle(from text: String) -> String {
        let lowercased = text.lowercased()
        
        if lowercased.contains("knife") || lowercased.contains("naked") || lowercased.contains("running") {
            let location = extractLocation(from: text) ?? "The Center"
            return "Man with knife spotted at \(location)"
        } else if lowercased.contains("fire") {
            return "Fire breakout detected"
        } else if lowercased.contains("traffic") {
            return "Traffic incident reported"
        } else {
            return "Incident reported"
        }
    }
    
    private func extractLocation(from text: String) -> String? {
        let locations = ["central", "queen's road", "the center", "admiralty", "causeway bay"]
        let lowercased = text.lowercased()
        
        for location in locations {
            if lowercased.contains(location) {
                return location.capitalized
            }
        }
        return nil
    }
    
    /// 환영 메시지 추가
    private func addBotWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            content: """
            Hello! I'm the Citizen Alert chatbot. 👋
            
            Type "help" if you need assistance.
            """,
            isUser: false
        )
        messages.append(welcomeMessage)
    }
    
    /// 대화 초기화
    func clearChat() {
        messages.removeAll()
        addBotWelcomeMessage()
    }
}
