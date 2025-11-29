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
    /// 테스트 서버: http://43.154.113.11:8080
    /// 
    /// 로컬 개발 시 사용 가능한 옵션:
    /// - 시뮬레이터: http://localhost:8080
    /// - 실제 기기: http://10.68.209.21:8080
    static var baseURL: String {
        return "http://43.154.113.11:8080"
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

