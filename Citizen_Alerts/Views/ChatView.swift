//
//  ChatView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI
import PhotosUI
import UIKit

struct ChatView: View {
    @StateObject private var chatService = ChatService.shared
    @State private var messageText = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                customHeader
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(chatService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if chatService.isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                    }
                    .onChange(of: chatService.messages.count) {
                        if let lastMessage = chatService.messages.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Input area
                messageInputArea
            }
        }
        .onChange(of: selectedPhotos) { oldValue, newValue in
            loadImages(from: newValue)
        }
    }
    
    // MARK: - Custom Header
    private var customHeader: some View {
        HStack(spacing: 12) {
            // Close Button
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
            
            // Chatbot Info
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Chatbot Assistant")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 10, height: 10)
                            .shadow(color: Color.green.opacity(0.5), radius: 4, x: 0, y: 2)
                        
                        Text("Online")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Profile Icon
            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.purple.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Text("M")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            ZStack {
                Color(.systemBackground)
                
                // Subtle gradient overlay
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.03),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator).opacity(0.5)),
            alignment: .bottom
        )
    }
    
    // MARK: - Message Input Area
    private var messageInputArea: some View {
        VStack(spacing: 0) {
            // Image preview if any
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                                
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedImages.remove(at: index)
                                        selectedPhotos.remove(at: index)
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 24, height: 24)
                                        
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                .padding(.bottom, 12)
            }
            
        HStack(spacing: 12) {
                // Camera/Photo Picker Button
                PhotosPicker(
                    selection: $selectedPhotos,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray6), Color(.systemGray5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
                
                // Text Input
                TextField("Type a message...", text: $messageText)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(
                                        isTextFieldFocused
                                            ? LinearGradient(
                                                colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : LinearGradient(
                                                colors: [Color.clear],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                        lineWidth: isTextFieldFocused ? 2 : 0
                                    )
                            )
                    )
                .focused($isTextFieldFocused)
                .onSubmit {
                    sendMessage()
                }
            
                // Send Button
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    sendMessage()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                messageText.isEmpty && selectedImages.isEmpty
                                    ? LinearGradient(
                                        colors: [Color(.systemGray4), Color(.systemGray5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(
                                color: messageText.isEmpty && selectedImages.isEmpty
                                    ? Color.clear
                                    : Color.blue.opacity(0.4),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(messageText.isEmpty && selectedImages.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    Color(.systemBackground)
                    
                    // Subtle gradient overlay
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.02),
                            Color.clear
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                }
            )
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator).opacity(0.5)),
                alignment: .top
            )
        }
    }
    
    // MARK: - Helper Functions
    private func loadImages(from items: [PhotosPickerItem]) {
        Task {
            var loadedImages: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    loadedImages.append(image)
                }
            }
            await MainActor.run {
                selectedImages = loadedImages
            }
        }
    }
    
    private func sendMessage() {
        let hasText = !messageText.trimmingCharacters(in: .whitespaces).isEmpty
        let hasImages = !selectedImages.isEmpty
        
        guard hasText || hasImages else { return }
        
        let imageCount = selectedImages.count
        var messageContent = messageText
        
        if imageCount > 0 {
            let imageText = imageCount == 1 ? "Attached 1 image" : "Attached \(imageCount) images"
            if messageContent.isEmpty {
                messageContent = imageText
            } else {
                messageContent = "\(messageText)\n\n\(imageText)"
            }
        }
        
        chatService.sendMessage(messageContent, images: selectedImages)
        messageText = ""
        selectedImages = []
        selectedPhotos = []
        isTextFieldFocused = true
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @State private var isAppeared = false
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
            HStack(alignment: .bottom, spacing: 10) {
                if !message.isUser {
                Spacer()
            }
            
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                    // Image attachments
                    if !message.images.isEmpty {
                        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(message.images.enumerated()), id: \.offset) { index, image in
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 140, height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: 16))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                            )
                                            .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                                    }
                                }
                            }
                            .frame(maxWidth: 280)
                            
                            Text(message.imageCountText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                        }
                        .padding(.bottom, 2)
                    }
                    
                    // Image attachments indicator (if no actual images but has indicator)
                    if message.hasImages && message.images.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.fill")
                                .font(.system(size: 11, weight: .medium))
                            Text(message.imageCountText)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(.secondary)
                        .padding(.bottom, 2)
                    }
                    
                    // Message content
                    if !message.content.isEmpty {
                Text(message.content)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(message.isUser ? .white : .primary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 14)
                            .background(
                                Group {
                                    if message.isUser {
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    } else {
                                        LinearGradient(
                                            colors: [Color(.systemGray6), Color(.systemGray5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    }
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(
                                        message.isUser
                                            ? Color.white.opacity(0.2)
                                            : Color(.systemGray4).opacity(0.5),
                                        lineWidth: 0.5
                                    )
                            )
                            .shadow(
                                color: message.isUser
                                    ? Color.blue.opacity(0.3)
                                    : Color.black.opacity(0.08),
                                radius: message.isUser ? 12 : 8,
                                x: 0,
                                y: message.isUser ? 6 : 4
                            )
                    }
                    
                    // Quick reply buttons if available
                    if let quickReplies = message.quickReplies {
                        HStack(spacing: 10) {
                            ForEach(quickReplies, id: \.self) { reply in
                                Button(action: {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    // Handle quick reply
                                }) {
                                    Text(reply)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [Color(.systemGray6), Color(.systemGray5)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                        .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 0.5)
                                                )
                                        )
                                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                .opacity(isAppeared ? 1 : 0)
                .offset(x: isAppeared ? 0 : (message.isUser ? 20 : -20))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isAppeared)
                
                if message.isUser {
                    Spacer()
                }
            }
            
            // Timestamp
            Text(formatTime(message.timestamp))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
                .padding(.horizontal, 8)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAppeared = true
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct TypingIndicator: View {
    @State private var animationAmounts: [CGFloat] = [0.5, 0.5, 0.5]
    
    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray3), Color(.systemGray4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 10, height: 10)
                        .scaleEffect(animationAmounts[index])
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.15),
                            value: animationAmounts[index]
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color(.systemGray4).opacity(0.5), lineWidth: 0.5)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            
            Spacer()
        }
        .onAppear {
            for index in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    animationAmounts[index] = 1.3
                }
            }
        }
    }
}


#Preview {
    ChatView()
}
