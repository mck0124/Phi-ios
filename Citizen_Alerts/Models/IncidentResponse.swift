//
//  IncidentResponse.swift
//  Citizen Alerts
//
//  Created on 11/24/25.
//

import Foundation

/// 위치 좌표
struct LocationCoordinates: Codable {
    let latitude: Double?
    let longitude: Double?
}

/// 백엔드 Incident 응답
struct IncidentResponse: Codable, Identifiable {
    let incidentId: Int64?
    let type: String?
    let locationCoordinates: LocationCoordinates?
    let locationDescription: String?
    let urgency: Int?
    let credibility: Int?
    let isOngoing: Bool?
    let firstReportedAt: String? // ISO 8601 format string
    let lastReportedAt: String? // ISO 8601 format string
    let description: String?
    
    var id: Int64 { incidentId ?? .zero }
    
    /// Convert ISO 8601 date string to Date
    var firstReportedAtDate: Date? {
        guard let dateString = firstReportedAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    var lastReportedAtDate: Date? {
        guard let dateString = lastReportedAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
}


