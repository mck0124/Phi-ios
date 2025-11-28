//
//  SignupView.swift
//  Citizen_Alerts
//
//  Created on 11/19/25.
//

import SwiftUI

struct SignupView: View {
    @State private var nickname: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var dob: String = ""
    @State private var gender: String = ""
    @State private var lastLocation: String = ""
    
    @State private var nicknameTouched: Bool = false
    @State private var nameTouched: Bool = false
    @State private var emailTouched: Bool = false
    @State private var passwordTouched: Bool = false
    @State private var confirmPasswordTouched: Bool = false
    
    @State private var signupError: String? = nil
    @State private var isSubmitting: Bool = false
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    private var isNicknameValid: Bool {
        nickname.count >= 2 && nickname.count <= 20
    }
    
    private var isNameValid: Bool {
        name.count >= 1 && name.count <= 30
    }
    
    private var isEmailValid: Bool {
        Validator.validateEmail(email)
    }
    
    private var isPasswordValid: Bool {
        Validator.validatePassword(password)
    }
    
    private var isConfirmPasswordValid: Bool {
        !confirmPassword.isEmpty && password == confirmPassword
    }
    
    private var canSubmit: Bool {
        isNicknameValid && isNameValid && isEmailValid && isPasswordValid && isConfirmPasswordValid
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 밝은 배경
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Compact header
                        VStack(spacing: 20) {
                            Image("phi_with_text")
                                .renderingMode(.template)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 40)
                                .foregroundStyle(Color("primaryBlue"))
                                .padding(.top, 60)
                            
                            VStack(spacing: 8) {
                                Text("Create your Account")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text("Fill in your information to get started")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 40)
                        
                        // Sign up form - centered
                        VStack(alignment: .leading, spacing: 16) {
                            // Nickname field
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Nickname (2-20 characters)",
                                          text: $nickname,
                                          onEditingChanged: { began in
                                    if !began { nicknameTouched = true }
                                })
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(nicknameTouched && !isNicknameValid ? Color.red : Color.clear, lineWidth: 1.5)
                                        )
                                )
                                
                                if nicknameTouched && !isNicknameValid {
                                    Text("Nickname must be 2-20 characters.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // Name field
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Full name (1-30 characters)",
                                          text: $name,
                                          onEditingChanged: { began in
                                    if !began { nameTouched = true }
                                })
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled(false)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(nameTouched && !isNameValid ? Color.red : Color.clear, lineWidth: 1.5)
                                        )
                                )
                                
                                if nameTouched && !isNameValid {
                                    Text("Name must be 1-30 characters.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Email address",
                                          text: $email,
                                          onEditingChanged: { began in
                                    if !began { emailTouched = true }
                                })
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(emailTouched && !isEmailValid ? Color.red : Color.clear, lineWidth: 1.5)
                                        )
                                )
                                
                                if emailTouched && !isEmailValid {
                                    Text("Please enter a valid email address.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                SecureField("Password (min 8 characters)",
                                            text: $password,
                                            onCommit: {
                                    passwordTouched = true
                                })
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(passwordTouched && !isPasswordValid ? Color.red : Color.clear, lineWidth: 1.5)
                                        )
                                )
                                .onChange(of: password) { _, _ in
                                    passwordTouched = true
                                }
                                
                                // Password strength indicator
                                if !password.isEmpty {
                                    PasswordStrengthView(password: password)
                                        .transition(.opacity)
                                }
                                
                                if passwordTouched && !isPasswordValid && !password.isEmpty {
                                    Text("Password does not meet all requirements.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // Confirm Password field
                            VStack(alignment: .leading, spacing: 4) {
                                SecureField("Confirm password",
                                            text: $confirmPassword,
                                            onCommit: {
                                    confirmPasswordTouched = true
                                })
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray6))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(confirmPasswordTouched && !isConfirmPasswordValid ? Color.red : Color.clear, lineWidth: 1.5)
                                        )
                                )
                                
                                if confirmPasswordTouched && !isConfirmPasswordValid {
                                    Text("Passwords do not match.")
                                        .font(.system(size: 13))
                                        .foregroundColor(.red)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            // Optional fields
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Optional Information")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                
                                TextField("Date of Birth (YYYY-MM-DD)", text: $dob)
                                    .keyboardType(.numbersAndPunctuation)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                
                                TextField("Gender (M/F/OTHER)", text: $gender)
                                    .textInputAutocapitalization(.never)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                
                                TextField("Location", text: $lastLocation)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                            }
                            
                            // Sign Up button
                            Button(action: {
                                guard canSubmit else { return }
                                
                                signupError = nil
                                isSubmitting = true
                                
                                Task {
                                    do {
                                        let signupRequest = SignupRequest(
                                            nickname: nickname,
                                            name: name,
                                            email: email,
                                            password: password,
                                            dob: dob.isEmpty ? nil : dob,
                                            gender: gender.isEmpty ? nil : gender,
                                            lastLocation: lastLocation.isEmpty ? nil : lastLocation
                                        )
                                        
                                        let userResponse = try await AuthAPI.signup(signupRequest)
                                        print("Signed up as \(userResponse.email ?? "unknown")")
                                        
                                        // 회원가입 성공 후 자동 로그인
                                        let loginResponse = try await AuthAPI.login(email: email, password: password)
                                        let user = User(from: loginResponse.user)
                                        authManager.login(user: user, token: loginResponse.token)
                                        
                                        await MainActor.run {
                                            isSubmitting = false
                                        }
                                    } catch APIError.serverError(let message) {
                                        await MainActor.run {
                                            signupError = message
                                            isSubmitting = false
                                        }
                                    } catch APIError.invalidURL {
                                        await MainActor.run {
                                            signupError = "Invalid server URL. Please check your connection settings."
                                            isSubmitting = false
                                        }
                                    } catch APIError.invalidStatusCode(let code) {
                                        await MainActor.run {
                                            signupError = "Server error (Status: \(code)). Please try again."
                                            isSubmitting = false
                                        }
                                    } catch let urlError as URLError {
                                        await MainActor.run {
                                            switch urlError.code {
                                            case .notConnectedToInternet:
                                                signupError = "No internet connection. Please check your network."
                                            case .cannotFindHost, .cannotConnectToHost:
                                                signupError = "Cannot connect to server. Please check if the server is running at \(APIConfig.baseURL)."
                                            case .timedOut:
                                                signupError = "Connection timed out. Please try again."
                                            default:
                                                signupError = "Network error: \(urlError.localizedDescription)"
                                            }
                                            isSubmitting = false
                                        }
                                    } catch {
                                        await MainActor.run {
                                            signupError = "Could not reach server. Please try again. Error: \(error.localizedDescription)"
                                            isSubmitting = false
                                        }
                                        print("Signup error:", error)
                                    }
                                }
                            }) {
                                HStack {
                                    if isSubmitting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    Text(isSubmitting ? "Creating Account..." : "Sign Up")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            Color("navyGray"),
                                            Color("navyGray").opacity(0.85)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color("navyGray").opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .disabled(!canSubmit || isSubmitting)
                            .opacity(canSubmit && !isSubmitting ? 1.0 : 0.5)
                            
                            if let signupError {
                                Text(signupError)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                                    .padding(.leading, 4)
                            }
                            
                            // Sign in option
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Sign In")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color("primaryBlue"))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                        }
                        .frame(maxWidth: 400)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct PasswordStrengthView: View {
    let password: String
    
    private var strength: PasswordStrength {
        Validator.evaluatePasswordStrength(password)
    }
    
    private var strengthColor: Color {
        switch strength {
        case .veryWeak: return .red
        case .weak: return .orange
        case .medium: return .yellow
        case .strong: return .green
        case .veryStrong: return Color("primaryBlue")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Strength bar
            ZStack(alignment: .leading) {
                // Background bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                
                // Progress bar - using scaleEffect with animation
                RoundedRectangle(cornerRadius: 4)
                    .fill(strengthColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
                    .scaleEffect(x: strength.progress, anchor: .leading)
            }
            .frame(height: 4)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: strength.progress)
            .animation(.easeInOut(duration: 0.4), value: strengthColor)
            
            // Strength text
            HStack {
                Text("Password strength: ")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(strength.description)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(strengthColor)
                    .contentTransition(.opacity)
            }
            .animation(.easeInOut(duration: 0.3), value: strength.description)
            .animation(.easeInOut(duration: 0.3), value: strengthColor)
            
            // Requirements checklist
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Validator.getPasswordRequirements(password), id: \.requirement) { req in
                    HStack(spacing: 6) {
                        Image(systemName: req.met ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(req.met ? .green : .gray)
                            .scaleEffect(req.met ? 1.15 : 1.0)
                        Text(req.requirement)
                            .font(.system(size: 11))
                            .foregroundColor(req.met ? .green : .secondary)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: req.met)
                }
            }
            .padding(.top, 2)
        }
        .padding(.leading, 4)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: password)
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        SignupView()
            .environmentObject(AuthManager.shared)
    }
}
