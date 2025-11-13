//
//  Alert.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import Foundation
import CoreLocation
import SwiftUI

/// 알림/경고 타입
enum AlertType: String, Codable, CaseIterable, Identifiable {
    case fire = "Fire"
    case traffic = "Traffic Accident"
    case emergency = "Emergency"
    case crime = "Crime"
    case disaster = "Disaster"
    case publicSafety = "Public Safety"
    case weather = "Weather Alert"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .fire: return "flame.fill"
        case .traffic: return "car.fill"
        case .emergency: return "cross.fill"
        case .crime: return "shield.fill"
        case .disaster: return "cloud.bolt.fill"
        case .publicSafety: return "exclamationmark.triangle.fill"
        case .weather: return "cloud.rain.fill"
        case .other: return "info.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .fire: return "red"
        case .traffic: return "orange"
        case .emergency: return "red"
        case .crime: return "purple"
        case .disaster: return "blue"
        case .publicSafety: return "yellow"
        case .weather: return "cyan"
        case .other: return "gray"
        }
    }
    
    var uiColor: Color {
        switch self {
        case .fire: return .red
        case .traffic: return .orange
        case .emergency: return .red
        case .crime: return .purple
        case .disaster: return .blue
        case .publicSafety: return .yellow
        case .weather: return .cyan
        case .other: return .gray
        }
    }
}

/// 경고 심각도
enum Severity: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .low: return "blue"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var iconColor: String {
        switch self {
        case .low: return "cyan"
        case .medium: return "green"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
    
    var uiColor: Color {
        switch self {
        case .low: return .blue
        case .medium: return Color(red: 1.0, green: 0.8, blue: 0.0) // 더 진한 노란색
        case .high: return Color(red: 1.0, green: 0.4, blue: 0.0) // 더 진한 주황색 (거의 빨간색)
        case .critical: return .red
        }
    }
}

/// 알림 데이터 모델
struct Alert: Identifiable, Codable, Equatable {
    let id: UUID
    let type: AlertType
    let title: String
    let description: String?
    let location: LocationData
    let severity: Severity
    let createdAt: Date
    let updatedAt: Date
    var photos: [String] // 이미지 URL 또는 파일명
    var isVerified: Bool
    var reportCount: Int // 중복 신고 카운트
    var reporterId: String? // 신고자 ID (익명 가능)
    
    init(
        id: UUID = UUID(),
        type: AlertType,
        title: String,
        description: String? = nil,
        location: LocationData,
        severity: Severity = .medium,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        photos: [String] = [],
        isVerified: Bool = false,
        reportCount: Int = 1,
        reporterId: String? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.location = location
        self.severity = severity
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.photos = photos
        self.isVerified = isVerified
        self.reportCount = reportCount
        self.reporterId = reporterId
    }
}

/// 위치 데이터
struct LocationData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    var address: String?
    var city: String?
    
    init(latitude: Double, longitude: Double, address: String? = nil, city: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.city = city
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// 신고 입력 데이터
struct AlertInput: Identifiable {
    let id: UUID = UUID()
    var type: AlertType
    var title: String
    var description: String
    var photos: [AlertPhoto]
    var location: LocationData?
    var severity: Severity
    var anonymityLevel: AnonymityLevel
    
    init(
        type: AlertType = .other,
        title: String = "",
        description: String = "",
        photos: [AlertPhoto] = [],
        location: LocationData? = nil,
        severity: Severity = .medium,
        anonymityLevel: AnonymityLevel = .anonymous
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.photos = photos
        self.location = location
        self.severity = severity
        self.anonymityLevel = anonymityLevel
    }
}

/// 알림 사진
struct AlertPhoto: Identifiable, Equatable {
    let id: UUID = UUID()
    let imageData: Data
    let thumbnailData: Data?
    
    init(imageData: Data, thumbnailData: Data? = nil) {
        self.imageData = imageData
        self.thumbnailData = thumbnailData
    }
}

/// 익명성 레벨
enum AnonymityLevel: String, Codable, CaseIterable {
    case anonymous = "Fully Anonymous"
    case nickname = "Nickname Only"
    case verified = "Verified Identity"
}
