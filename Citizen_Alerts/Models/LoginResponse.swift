//
//  LoginResponse.swift
//  Citizen_Alerts
//
//  Created on 11/19/25.
//

import Foundation

/// 로그인 응답 모델 (JWT 토큰 포함)
struct LoginResponse: Codable {
    let token: String
    let tokenType: String
    let user: UserResponseDTO
}


