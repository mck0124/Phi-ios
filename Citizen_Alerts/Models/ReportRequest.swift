//
//  ReportRequest.swift
//  Citizen Alerts
//
//  Created on 11/24/25.
//

import Foundation

struct ReportLocationCoordinatesDTO: Codable {
    let latitude: Double
    let longitude: Double
}

/// 신규 리포트 생성 요청
struct ReportRequestDTO: Codable {
    let locationCoordinates: ReportLocationCoordinatesDTO
    let locationDescription: String?
    let incidentType: String?
    let credibility: Int
    let urgency: Int
    let reportType: String
    let description: String?
    let incidentId: Int64?
}


