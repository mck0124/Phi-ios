//
//  Validations.swift
//  Citizen_Alerts
//
//  Created by Mina on 11/18/25.
//

// Checks if the signup inputs are valid

import Foundation

enum PasswordStrength {
    case veryWeak
    case weak
    case medium
    case strong
    case veryStrong
    
    var description: String {
        switch self {
        case .veryWeak: return "Very Weak"
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        case .veryStrong: return "Very Strong"
        }
    }
    
    var color: String {
        switch self {
        case .veryWeak: return "red"
        case .weak: return "orange"
        case .medium: return "yellow"
        case .strong: return "green"
        case .veryStrong: return "primaryBlue"
        }
    }
    
    var progress: Double {
        switch self {
        case .veryWeak: return 0.2
        case .weak: return 0.4
        case .medium: return 0.6
        case .strong: return 0.8
        case .veryStrong: return 1.0
        }
    }
}

enum Validator {
    static func validateEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    static func validatePassword(_ password: String) -> Bool {
        let passwordRegex = "^(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$"
        
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        return passwordPredicate.evaluate(with: password)
    }
    
    /// Evaluates password strength in real-time as user types
    static func evaluatePasswordStrength(_ password: String) -> PasswordStrength {
        if password.isEmpty {
            return .veryWeak
        }
        
        var score = 0
        
        // Length checks
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.count >= 16 { score += 1 }
        
        // Character variety checks
        if password.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet.lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: CharacterSet(charactersIn: "@$!%*?&")) != nil { score += 1 }
        
        // Determine strength based on score
        switch score {
        case 0...2:
            return .veryWeak
        case 3...4:
            return .weak
        case 5...6:
            return .medium
        case 7...8:
            return .strong
        default:
            return .veryStrong
        }
    }
    
    /// Returns detailed requirements that are met/not met
    static func getPasswordRequirements(_ password: String) -> [(requirement: String, met: Bool)] {
        return [
            ("At least 8 characters", password.count >= 8),
            ("One uppercase letter", password.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil),
            ("One number", password.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil),
            ("One special character (@$!%*?&)", password.rangeOfCharacter(from: CharacterSet(charactersIn: "@$!%*?&")) != nil)
        ]
    }
}
