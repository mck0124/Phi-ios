//
//  ReportAPI.swift
//  Citizen Alerts
//
//  Created on 11/24/25.
//

import Foundation

enum ReportAPI {
    private static let network = NetworkManager.shared
    
    /// 리포트 생성
    static func createReport(_ request: ReportRequestDTO) async throws -> ReportResponseDTO {
        guard let url = URL(string: APIConfig.apiPath("reports/v1")) else {
            throw APIError.invalidURL
        }
        let body = try JSONEncoder().encode(request)
        return try await network.request(
            url: url,
            method: .POST,
            body: body
        )
    }
    
    /// 인시던트 목록 조회 (인증 불필요)
    static func fetchIncidents(isOngoing: Bool? = nil) async throws -> [IncidentResponse] {
        var components = URLComponents(string: APIConfig.apiPath("incidents"))
        var queryItems: [URLQueryItem] = []
        
        if let isOngoing = isOngoing {
            queryItems.append(URLQueryItem(name: "isOngoing", value: isOngoing ? "true" : "false"))
        }
        
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else {
            throw APIError.invalidURL
        }
        
        print("🔵 [ReportAPI] Fetching incidents from: \(url.absoluteString)")
        let incidents = try await network.request(url: url) as [IncidentResponse]
        print("✅ [ReportAPI] Successfully fetched \(incidents.count) incidents")
        return incidents
    }
}


