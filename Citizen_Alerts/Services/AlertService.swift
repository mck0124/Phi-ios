//
//  AlertService.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import Foundation
import Combine
import CoreLocation

/// 알림 관리 서비스
@MainActor
class AlertService: ObservableObject {
    static let shared = AlertService()
    
    @Published var alerts: [Alert] = []
    @Published var isLoading = false
    @Published var error: AlertError?
    
    private let locationManager = LocationManager.shared
    
    private init() {
        Task {
            await self.loadLatestIncidents()
        }
    }
    
    /// 백엔드에서 최신 알림 가져오기
    func fetchAlerts(isOngoing: Bool? = true) async {
        await loadLatestIncidents(isOngoing: isOngoing)
    }
    
    private func loadLatestIncidents(isOngoing: Bool? = true) async {
        isLoading = true
        error = nil
        
        do {
            print("🔵 [AlertService] Fetching incidents from backend...")
            let incidents = try await ReportAPI.fetchIncidents(isOngoing: isOngoing)
            print("✅ [AlertService] Received \(incidents.count) incidents from backend")
            
            let backendAlerts = incidents.compactMap(convertIncidentToAlert)
            print("✅ [AlertService] Converted to \(backendAlerts.count) alerts")
            
            alerts = backendAlerts.sorted { $0.createdAt > $1.createdAt }
            print("✅ [AlertService] Updated alerts array with \(alerts.count) items")
        } catch let fetchError {
            print("❌ [AlertService] Error fetching incidents: \(fetchError)")
            self.error = .networkError(fetchError.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// 필터링된 알림 가져오기
    func fetchAlerts(
        type: AlertType? = nil,
        withinRadius: Double? = nil,
        from location: CLLocationCoordinate2D? = nil
    ) -> [Alert] {
        var filteredAlerts = alerts
        
        // 타입 필터
        if let type = type {
            filteredAlerts = filteredAlerts.filter { $0.type == type }
        }
        
        // 거리 필터
        if let radius = withinRadius, let centerLocation = location ?? locationManager.userLocation {
            filteredAlerts = filteredAlerts.filter { alert in
                let distance = locationManager.distanceBetween(centerLocation, alert.location.coordinate)
                return distance <= radius
            }
        }
        
        return filteredAlerts.sorted { $0.createdAt > $1.createdAt }
    }
    
    /// 알림 생성 (리포트 제출)
    func createAlert(from input: AlertInput, photos: [AlertPhoto], incidentId: Int64? = nil) async throws -> Alert {
        guard let baseLocation = input.location ?? (
            locationManager.userLocation.map { LocationData(latitude: $0.latitude, longitude: $0.longitude) }
        ) else {
            throw AlertError.invalidLocation
        }
        
        let description = input.description.isEmpty ? nil : input.description
        let locationDescription = input.locationDescription.isEmpty ? input.location?.address : input.locationDescription
        let finalLocation = LocationData(
            latitude: baseLocation.latitude,
            longitude: baseLocation.longitude,
            address: locationDescription,
            city: baseLocation.city
        )
        
        let request = ReportRequestDTO(
            locationCoordinates: ReportLocationCoordinatesDTO(
                latitude: finalLocation.latitude,
                longitude: finalLocation.longitude
            ),
            locationDescription: locationDescription,
            incidentType: incidentId == nil ? backendIncidentType(for: input.type) : nil,
            credibility: credibilityValue(for: input.severity),
            urgency: urgencyValue(for: input.severity),
            reportType: "user",
            description: description,
            incidentId: incidentId
        )
        
        do {
            let response = try await ReportAPI.createReport(request)
            let createdAt = response.timestamp ?? Date()
            let createdAlert = Alert(
                type: input.type,
                incidentId: response.incidentId ?? incidentId,
                title: input.title.isEmpty ? input.type.rawValue : input.title,
                description: description ?? response.description,
                location: finalLocation,
                severity: input.severity,
                createdAt: createdAt,
                updatedAt: createdAt,
                photos: [],
                isVerified: (response.credibility ?? 0) > 50,
                reportCount: 1
            )
            
            await loadLatestIncidents()
            return createdAlert
        } catch let submitError {
            throw AlertError.networkError(submitError.localizedDescription)
        }
    }
    
    /// 알림 업데이트 (재신고 등)
    func updateAlert(_ alert: Alert) async throws {
        guard let index = alerts.firstIndex(where: { $0.id == alert.id }) else {
            throw AlertError.alertNotFound
        }
        
        alerts[index] = alert
        // TODO: API 호출
    }
    
    /// 알림 삭제
    func deleteAlert(_ alert: Alert) async throws {
        alerts.removeAll { $0.id == alert.id }
        // TODO: API 호출
    }
    
    /// 알림 신고 수 증가 (중복 신고)
    func incrementReportCount(for alertId: UUID) async throws {
        guard let index = alerts.firstIndex(where: { $0.id == alertId }) else {
            throw AlertError.alertNotFound
        }
        
        var updatedAlert = alerts[index]
        updatedAlert.reportCount += 1
        alerts[index] = updatedAlert
        
        // TODO: API 호출
    }
    
    /// 주변 알림 검색
    func getNearbyAlerts(center: CLLocationCoordinate2D, radius: Double = 10.0) -> [Alert] {
        return fetchAlerts(withinRadius: radius, from: center)
    }
    
    // MARK: - Backend Mapping Helpers
    
    private func convertIncidentToAlert(_ incident: IncidentResponse) -> Alert? {
        // Parse location from locationCoordinates object
        guard let coordinates = incident.locationCoordinates,
              let latitude = coordinates.latitude,
              let longitude = coordinates.longitude else {
            print("⚠️ [AlertService] Skipping incident \(incident.incidentId ?? 0): missing location coordinates")
            return nil
        }
        
        let locationData = LocationData(
            latitude: latitude,
            longitude: longitude,
            address: incident.locationDescription,
            city: nil
        )
        
        let alertType = alertType(from: incident.type)
        let createdAt = incident.firstReportedAtDate ?? Date()
        let updatedAt = incident.lastReportedAtDate ?? createdAt
        let severity = severityLevel(fromUrgency: incident.urgency, credibility: incident.credibility)
        
        let alert = Alert(
            type: alertType,
            incidentId: incident.incidentId,
            title: incident.description ?? alertType.rawValue,
            description: incident.description,
            location: locationData,
            severity: severity,
            createdAt: createdAt,
            updatedAt: updatedAt,
            photos: [],
            isVerified: (incident.credibility ?? 0) > 60,
            reportCount: 1
        )
        
        print("✅ [AlertService] Converted incident \(incident.incidentId ?? 0) to alert at (\(latitude), \(longitude))")
        return alert
    }
    
    private func parseLocationData(from string: String?) -> LocationData? {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines),
              !string.isEmpty else {
            return nil
        }
        
        if string.uppercased().hasPrefix("POINT") {
            let cleaned = string
                .replacingOccurrences(of: "POINT", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = cleaned.split(whereSeparator: { $0 == " " })
            if parts.count >= 2,
               let longitude = Double(parts[0]),
               let latitude = Double(parts[1]) {
                return LocationData(latitude: latitude, longitude: longitude)
            }
        } else if string.contains(",") {
            let parts = string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2,
               let latitude = Double(parts[0]),
               let longitude = Double(parts[1]) {
                return LocationData(latitude: latitude, longitude: longitude)
            }
        }
        return nil
    }
    
    private func severityLevel(fromUrgency urgency: Int?, credibility: Int?) -> Severity {
        let urgencyScore = Double(urgency ?? 0)
        let credibilityScore = Double(credibility ?? 0)
        let blended = (urgencyScore * 0.7) + (credibilityScore * 0.3)
        
        switch blended {
        case ..<25:
            return .low
        case ..<60:
            return .medium
        case ..<85:
            return .high
        default:
            return .critical
        }
    }
    
    private func alertType(from backendType: String?) -> AlertType {
        guard let backendType = backendType?.uppercased() else {
            return .other
        }
        
        switch backendType {
        case "CRIME":
            return .crime
        case "FIRE":
            return .fire
        case "DISASTER":
            return .disaster
        default:
            return .other
        }
    }
    
    private func backendIncidentType(for alertType: AlertType) -> String {
        switch alertType {
        case .crime:
            return "CRIME"
        case .fire:
            return "FIRE"
        case .disaster, .weather:
            return "DISASTER"
        default:
            return "ETC"
        }
    }
    
    private func urgencyValue(for severity: Severity) -> Int {
        switch severity {
        case .low: return 25
        case .medium: return 55
        case .high: return 75
        case .critical: return 95
        }
    }
    
    private func credibilityValue(for severity: Severity) -> Int {
        switch severity {
        case .low: return 30
        case .medium: return 50
        case .high: return 70
        case .critical: return 90
        }
    }
    
    // MARK: - Sample Data
    
    private func loadSampleAlerts() {
        alerts = [
            Alert(
                type: .fire,
                incidentId: 1,
                title: "Fire Report in Central District",
                description: "Smoke visible from building near Central MTR station.",
                location: LocationData(latitude: 22.2819, longitude: 114.1577, address: "Central District", city: "Hong Kong"),
                severity: .high,
                createdAt: Date().addingTimeInterval(-300),
                photos: ["fire1", "fire2", "fire3"],
                reportCount: 5,
                reporterId: "user1"
            ),
            Alert(
                type: .traffic,
                incidentId: 2,
                title: "Traffic Accident Reported",
                description: "Vehicle collision at Admiralty intersection.",
                location: LocationData(latitude: 22.2783, longitude: 114.1653, address: "Admiralty", city: "Hong Kong"),
                severity: .medium,
                createdAt: Date().addingTimeInterval(-720),
                photos: ["traffic1", "traffic2"],
                reportCount: 3,
                reporterId: "user2"
            ),
            Alert(
                type: .emergency,
                incidentId: 3,
                title: "Medical Emergency",
                description: "Person collapsed near Tsim Sha Tsui MTR station.",
                location: LocationData(latitude: 22.2974, longitude: 114.1720, address: "Tsim Sha Tsui", city: "Hong Kong"),
                severity: .critical,
                createdAt: Date().addingTimeInterval(-1080),
                photos: ["emergency1"],
                reportCount: 8,
                reporterId: "user3"
            ),
            Alert(
                type: .crime,
                incidentId: 4,
                title: "Suspicious Activity",
                description: "Person loitering suspiciously in narrow alley.",
                location: LocationData(latitude: 22.2783, longitude: 114.1653, address: "Wan Chai", city: "Hong Kong"),
                severity: .medium,
                createdAt: Date().addingTimeInterval(-1800),
                photos: ["crime1", "crime2", "crime3", "crime4"],
                reportCount: 2,
                reporterId: "user4"
            ),
            Alert(
                type: .disaster,
                incidentId: 5,
                title: "Strong Wind Warning",
                description: "Strong winds expected this afternoon.",
                location: LocationData(latitude: 22.3193, longitude: 114.1694, address: "Hong Kong Island", city: "Hong Kong"),
                severity: .low,
                createdAt: Date().addingTimeInterval(-3600),
                reportCount: 1,
                reporterId: "user5"
            )
        ]
    }
}

/// 알림 관련 에러
enum AlertError: LocalizedError {
    case invalidLocation
    case alertNotFound
    case uploadFailed
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Invalid location."
        case .alertNotFound:
            return "Alert not found."
        case .uploadFailed:
            return "Upload failed."
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
