//
//  APIConfig.swift
//  Citizen_Alerts
//
//  Created on 11/19/25.
//

import Foundation

/// API 설정 관리
struct APIConfig {
    /// 백엔드 서버 base URL
    /// 
    /// 시뮬레이터와 실제 기기를 자동으로 구분합니다:
    /// - 시뮬레이터: http://localhost:8080
    /// - 실제 기기: http://10.68.209.21:8080
    static var baseURL: String {
        return "http://43.154.113.11:8080"
//        #if targetEnvironment(simulator)
//        // iOS 시뮬레이터용
//        return "http://localhost:8080"
//        #else
//        // 실제 iOS 기기용
//        return "http://10.68.209.21:8080"
//        #endif
    }
    
    /// API 버전
    static let apiVersion = "v1"
    
    /// 전체 API 경로 생성
    static func apiPath(_ endpoint: String) -> String {
        return "\(baseURL)/api/\(endpoint)"
    }
    
    /// 타임아웃 설정 (초)
    static let timeout: TimeInterval = 30.0
}

