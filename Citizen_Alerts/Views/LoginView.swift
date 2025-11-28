//
//  LoginView.swift
//  Citizen_Alerts
//
//  Created by Mina on 11/18/25.
//

import SwiftUI

struct CheckBoxView: View { // apparently iOS checkbox toggle isn't default?!?!?!?! so yah declared
    @Binding var checked: Bool

    var body: some View {
        Image(systemName: checked ? "checkmark.square.fill" : "square")
            .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
            .onTapGesture {
                self.checked.toggle()
            }
    }
}

struct LoginView: View {
    @State private var navigateToEmailForm: Bool = false
    @State private var showSignup: Bool = false
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color("primaryBlue").opacity(0.08),
                        Color.white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        headerSection
                        Spacer(minLength: 250)
                        quickActionsSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
                
                NavigationLink(
                    destination: EmailLoginFormView()
                        .environmentObject(authManager),
                    isActive: $navigateToEmailForm
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .sheet(isPresented: $showSignup) {
                SignupView()
                    .environmentObject(authManager)
            }
        }
    }

}

// MARK: - Email Login Page
struct EmailLoginFormView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    @State private var emailTouched: Bool = false
    @State private var passwordTouched: Bool = false
    @State private var passwordVisible: Bool = false
    @State private var loginError: String? = nil
    @State private var showForgotPassword: Bool = false
    
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case email
        case password
    }
    
    private var isEmailValid: Bool { Validator.validateEmail(email) }
    private var isPasswordValid: Bool { Validator.validatePassword(password) }
    private var canSubmit: Bool { isEmailValid && isPasswordValid }
    
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sign in")
                            .font(.system(size: 26, weight: .semibold))
                        Text("Use your email and password to continue.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    
                    VStack(spacing: 16) {
                        emailField
                        passwordField
                        
                        HStack {
                            HStack(spacing: 6) {
                                CheckBoxView(checked: $rememberMe)
                                Text("Remember me")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                showForgotPassword = true
                            } label: {
                                Text("Forgot password")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color("primaryBlue"))
                            }
                        }
                        
                        Button(action: submitLogin) {
                            Text("Sign in")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color("primaryBlue"))
                                )
                                .shadow(color: Color("primaryBlue").opacity(0.25), radius: 10, x: 0, y: 8)
                        }
                        .disabled(!canSubmit)
                        .opacity(canSubmit ? 1.0 : 0.6)
                        
                        if let loginError {
                            Text(loginError)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 10)
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }
    
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "envelope")
                    .foregroundColor(.secondary)
                TextField("Email address", text: $email, onEditingChanged: { began in
                    if !began { emailTouched = true }
                })
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .email)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(emailTouched && !isEmailValid ? Color.red : Color.gray.opacity(0.2), lineWidth: 1.2)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            )
            
            if emailTouched && !isEmailValid {
                Text("Please enter a valid email address.")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(.secondary)
                
                Group {
                    if passwordVisible {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .focused($focusedField, equals: .password)
                .onSubmit {
                    passwordTouched = true
                }
                
                Button {
                    passwordVisible.toggle()
                } label: {
                    Image(systemName: passwordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(passwordTouched && !isPasswordValid ? Color.red : Color.gray.opacity(0.2), lineWidth: 1.2)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.systemGray6))
                    )
            )
            
            if passwordTouched && !isPasswordValid {
                Text("Min 8 chars, 1 capital letter, 1 number, 1 symbol.")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
            }
        }
    }
    
    private func submitLogin() {
        guard canSubmit else { return }
        loginError = nil
        emailTouched = true
        passwordTouched = true
        
        Task {
            do {
                let loginResponse = try await AuthAPI.login(email: email, password: password)
                print("Logged in as \(loginResponse.user.email ?? "unknown")")
                
                let user = User(from: loginResponse.user)
                authManager.login(user: user, token: loginResponse.token)
            } catch APIError.serverError(let message) {
                loginError = message
            } catch APIError.invalidStatusCode(401) {
                loginError = "Incorrect email or password."
            } catch APIError.invalidURL {
                loginError = "Invalid server URL. Please check your connection settings."
            } catch APIError.invalidStatusCode(let code) {
                loginError = "Server error (Status: \(code)). Please try again."
            } catch let urlError as URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    loginError = "No internet connection. Please check your network."
                case .cannotFindHost, .cannotConnectToHost:
                    loginError = "Cannot connect to server. Please check if the server is running at \(APIConfig.baseURL)."
                case .timedOut:
                    loginError = "Connection timed out. Please try again."
                default:
                    loginError = "Network error: \(urlError.localizedDescription)"
                }
            } catch {
                loginError = "Could not reach server. Please try again. Error: \(error.localizedDescription)"
                print("Login error:", error)
            }
        }
    }
}

// MARK: - UI Sections
private extension LoginView {
    var headerSection: some View {
        VStack(spacing: 18) {
            Image("phi_with_text")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 48)
                .foregroundStyle(Color("primaryBlue"))
                .padding(.top, 50)
            
            Text("Welcome! Please sign in")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
    
    var quickActionsSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                primaryButton(title: "Continue with email", icon: "envelope.fill") {
                    navigateToEmailForm = true
                }
                
                socialButton(title: "Continue with Google", icon: "g.circle.fill", tint: .black.opacity(0.85))
                socialButton(title: "Continue with Apple", icon: "applelogo", tint: .black)
            }
            
            VStack(spacing: 8) {
                Text("By continuing, you confirm you are 18 or over and agree to our Privacy Policy and Terms of Use.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                
                HStack(spacing: 4) {
                    Text("Don’t have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Button {
                        showSignup = true
                    } label: {
                        Text("Create an account")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("primaryBlue"))
                    }
                }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
    
    func primaryButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color("primaryBlue"))
            )
        }
    }
    
    func socialButton(title: String, icon: String, tint: Color) -> some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 13)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.white)
                    )
            )
        }
    }
    
}

//struct LoginView_Previews: PreviewProvider {
//    static var previews: some View {
//        LoginView()
//            .environmentObject(AuthManager.shared)
//    }
//}
