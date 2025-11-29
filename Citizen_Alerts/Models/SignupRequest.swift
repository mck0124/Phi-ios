//
//  SignupRequest.swift
//  Citizen_Alerts
//
//  Created on 11/19/25.
//

import Foundation

/// 회원가입 요청 모델
struct SignupRequest: Codable {
    let nickname: String
    let name: String
    let email: String
    let password: String
    let dob: String?
    let gender: String?
    let lastLocation: String?
}



