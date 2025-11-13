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
    case user = "사용자"
    case moderator = "관리자"
    case admin = "시스템관리자"
}
