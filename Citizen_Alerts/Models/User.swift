//
//  User.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import Foundation

/// 사용자 모델
struct User: Identifiable, Codable {
    let id: String
    var nickname: String?
    var email: String?
    var profileImage: String?
    var notificationEnabled: Bool
    var alertRadius: Double // km
    var blockedAlertTypes: Set<AlertType>
    var createdAt: Date
    var lastActiveAt: Date
    
    init(
        id: String,
        nickname: String? = nil,
        email: String? = nil,
        profileImage: String? = nil,
        notificationEnabled: Bool = true,
        alertRadius: Double = 10.0,
        blockedAlertTypes: Set<AlertType> = [],
        createdAt: Date = Date(),
        lastActiveAt: Date = Date()
    ) {
        self.id = id
        self.nickname = nickname
        self.email = email
        self.profileImage = profileImage
        self.notificationEnabled = notificationEnabled
        self.alertRadius = alertRadius
        self.blockedAlertTypes = blockedAlertTypes
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
    }
}

/// 사용자 권한
enum UserRole: String, Codable {
    case user = "User"
    case moderator = "Moderator"
    case admin = "Administrator"
}

// MARK: - Mapping from backend DTO

extension User {
    /// 백엔드에서 내려온 UserResponseDTO 를 앱 도메인 User 로 변환
    init(from dto: UserResponseDTO) {
        self.id = String(dto.userId)
        self.nickname = dto.nickname
        self.email = dto.email
        self.profileImage = nil

        // 기본값들은 앱 정책에 맞게 세팅
        self.notificationEnabled = true
        self.alertRadius = 10.0
        self.blockedAlertTypes = []

        // 서버에서 오는 createdAt/lastActiveAt 포맷을 아직 안 정했으면 일단 로컬 시각 사용
        self.createdAt = Date()
        self.lastActiveAt = Date()
    }
}
