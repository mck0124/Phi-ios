//
//  LocationManager.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import Foundation
import CoreLocation
import Combine
#if os(iOS)
import UIKit
#endif

/// 위치 관리 서비스
@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var currentLocation: CLLocation?
    @Published var isLoading = false
    @Published var error: LocationError?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 50 // 50미터마다 업데이트
        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// 위치 권한 요청
    func requestPermission() {
        guard authorizationStatus == .notDetermined else {
            handleAuthorizationStatus()
            return
        }
        
        // 위치 서비스가 활성화되어 있는지 확인
        guard CLLocationManager.locationServicesEnabled() else {
            error = .locationServicesDisabled
            return
        }
        
        #if os(iOS)
        locationManager.requestWhenInUseAuthorization()
        #else
        locationManager.requestAlwaysAuthorization()
        #endif
    }
    
    /// 위치 업데이트 시작
    func startLocationUpdates() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        #else
        guard authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        #endif
        
        isLoading = true
        locationManager.startUpdatingLocation()
    }
    
    /// 위치 업데이트 중지
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLoading = false
    }
    
    /// 한 번만 위치 가져오기
    func requestLocation() {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        #else
        guard authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        #endif
        
        isLoading = true
        locationManager.requestLocation()
    }
    
    private func handleAuthorizationStatus() {
        #if os(iOS)
        let isAuthorized = authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        #else
        let isAuthorized = authorizationStatus == .authorizedAlways
        #endif
        
        if isAuthorized {
            startLocationUpdates()
        } else {
            switch authorizationStatus {
            case .authorizedAlways:
                startLocationUpdates()
            #if os(iOS)
            case .authorizedWhenInUse:
                startLocationUpdates()
            #endif
            case .denied, .restricted:
                error = .permissionDenied
            case .notDetermined:
                requestPermission()
            @unknown default:
                break
            }
        }
    }
    
    /// 두 좌표 사이의 거리 계산 (km)
    func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000.0 // km
    }
    
    /// 설정 앱으로 이동
    func openSettings() {
        #if os(iOS)
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
        #endif
    }
    
    /// 위치 권한 상태 확인
    var canRequestLocation: Bool {
        return CLLocationManager.locationServicesEnabled() && 
               (authorizationStatus == .notDetermined || authorizationStatus == .denied)
    }
    
    /// 위치 권한이 거부되었는지 확인
    var isPermissionDenied: Bool {
        return authorizationStatus == .denied || authorizationStatus == .restricted
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        handleAuthorizationStatus()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        userLocation = location.coordinate
        currentLocation = location
        isLoading = false
        error = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        self.error = .locationUpdateFailed(error.localizedDescription)
    }
}

/// Location-related errors
enum LocationError: LocalizedError {
    case permissionDenied
    case locationUpdateFailed(String)
    case locationUnknown
    case locationServicesDisabled
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location access was denied. Please enable it in Settings."
        case .locationUpdateFailed(let message):
            return "Unable to fetch your location: \(message)"
        case .locationUnknown:
            return "Your current location is unknown."
        case .locationServicesDisabled:
            return "Location services are disabled. Enable them in Settings."
        }
    }
}
