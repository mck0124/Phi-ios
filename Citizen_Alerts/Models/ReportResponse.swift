//
//  ReportResponse.swift
//  Citizen Alerts
//
//  Created on 11/24/25.
//

import Foundation

/// 리포트 생성 응답
struct ReportResponseDTO: Codable, Identifiable {
    let reportId: Int64?
    let type: String?
    let locationCoordinates: ReportLocationCoordinatesDTO?
    let locationDescription: String?
    let credibility: Int?
    let urgency: Int?
    let reportType: String?
    let incidentId: Int64?
    let timestamp: Date?
    let description: String?
    
    var id: Int64 { reportId ?? .zero }
}


