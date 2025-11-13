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
    private var subscriptions = Set<AnyCancellable>()
    
    private init() {
        loadSampleAlerts()
    }
    
    /// 모든 알림 가져오기
    func fetchAlerts() async {
        isLoading = true
        error = nil
        
        // TODO: 실제 API 호출로 교체
        try? await Task.sleep(nanoseconds: 500_000_000)
        
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
    
    /// 알림 생성
    func createAlert(from input: AlertInput, photos: [AlertPhoto]) async throws -> Alert {
        guard let location = input.location ?? (
            locationManager.userLocation.map { LocationData(latitude: $0.latitude, longitude: $0.longitude) }
        ) else {
            throw AlertError.invalidLocation
        }
        
        let alert = Alert(
            type: input.type,
            title: input.title,
            description: input.description.isEmpty ? nil : input.description,
            location: location,
            severity: input.severity,
            photos: [],
            isVerified: false,
            reportCount: 1
        )
        
        // TODO: 사진 업로드 처리
        // TODO: API 호출
        
        alerts.append(alert)
        return alert
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
    
    // MARK: - Sample Data
    
    private func loadSampleAlerts() {
        alerts = [
            Alert(
                type: .fire,
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
