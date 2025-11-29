//
//  SettingsView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("alertRadius") private var alertRadius: Double = 10.0
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("autoRefreshEnabled") private var autoRefreshEnabled = true
    @AppStorage("language") private var language = "English"
    
    @State private var showingAbout = false
    @State private var showingLocationSettings = false
    @State private var showingNotificationSettings = false
    @State private var showingPrivacySettings = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    // Quick Settings
                    quickSettingsSection
                    
                    // Main Settings
                    mainSettingsSection
                    
                    // App Information
                    appInfoSection
                    
                    // Legal & Support
                    legalSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Settings")
            .navigationBarModifiers()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingLocationSettings) {
            LocationSettingsView()
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingPrivacySettings) {
            PrivacySettingsView()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("Citizen User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Active Member")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Quick Settings
    private var quickSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Settings")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickSettingCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: notificationsEnabled ? "On" : "Off",
                    color: notificationsEnabled ? .green : .gray,
                    action: { showingNotificationSettings = true }
                )
                
                QuickSettingCard(
                    icon: "location.fill",
                    title: "Location",
                    subtitle: "\(Int(alertRadius)) km",
                    color: .blue,
                    action: { showingLocationSettings = true }
                )
                
                QuickSettingCard(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    subtitle: darkModeEnabled ? "On" : "Off",
                    color: darkModeEnabled ? .purple : .gray,
                    action: { darkModeEnabled.toggle() }
                )
                
                QuickSettingCard(
                    icon: "shield.fill",
                    title: "Privacy",
                    subtitle: "Manage",
                    color: .orange,
                    action: { showingPrivacySettings = true }
                )
            }
        }
    }
    
    // MARK: - Main Settings
    private var mainSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "bell.fill",
                    title: "Push Notifications",
                    subtitle: "Receive alerts and updates",
                    trailing: AnyView(Toggle("", isOn: $notificationsEnabled))
                )
                
                SettingRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sound",
                    subtitle: "Play sounds for alerts",
                    trailing: AnyView(Toggle("", isOn: $soundEnabled))
                )
                
                SettingRow(
                    icon: "iphone.radiowaves.left.and.right",
                    title: "Vibration",
                    subtitle: "Vibrate for important alerts",
                    trailing: AnyView(Toggle("", isOn: $vibrationEnabled))
                )
                
                SettingRow(
                    icon: "arrow.clockwise",
                    title: "Auto Refresh",
                    subtitle: "Automatically update alerts",
                    trailing: AnyView(Toggle("", isOn: $autoRefreshEnabled))
                )
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - App Information
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "info.circle.fill",
                    title: "About Citizen Alerts",
                    subtitle: "Version 1.0.0",
                    trailing: AnyView(Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary))
                ) {
                    showingAbout = true
                }
                
                SettingRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "Get help and contact us",
                    trailing: AnyView(Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary))
                ) {
                    // Open help
                }
                
                SettingRow(
                    icon: "star.fill",
                    title: "Rate App",
                    subtitle: "Rate us on the App Store",
                    trailing: AnyView(Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary))
                ) {
                    // Open App Store rating
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Legal & Privacy")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "hand.raised.fill",
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    trailing: AnyView(Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary))
                ) {
                    // Open privacy policy
                }
                
                SettingRow(
                    icon: "doc.text.fill",
                    title: "Terms of Service",
                    subtitle: "App usage terms",
                    trailing: AnyView(Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary))
                ) {
                    // Open terms
                }
                
                SettingRow(
                    icon: "envelope.fill",
                    title: "Contact Us",
                    subtitle: "Send feedback or report issues",
                    trailing: AnyView(Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary))
                ) {
                    // Open contact
                }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 80))
                        .foregroundColor(.red)
                    
                    Text("Citizen Alerts")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Community Alert System")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About the App")
                            .font(.headline)
                        
                        Text("Provide rapid alerts and multi-source reports to keep the community safe. Data is shared so residents can stay informed about potential risks.")
                            .foregroundColor(.secondary)
                        
                        Text("Key Features")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            FeatureRow(icon: "map.fill", text: "Real-time safety map")
                            FeatureRow(icon: "bell.fill", text: "Proximity-based alerts")
                            FeatureRow(icon: "camera.fill", text: "Report with photos")
                            FeatureRow(icon: "message.fill", text: "Chatbot assistance")
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: trailingToolbarPlacement()) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Quick Setting Card
struct QuickSettingCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(color)
                    .cornerRadius(10)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Setting Row
struct SettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let trailing: AnyView
    let action: (() -> Void)?
    
    init(icon: String, title: String, subtitle: String, trailing: AnyView, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                trailing
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - Location Settings View
struct LocationSettingsView: View {
    @AppStorage("alertRadius") private var alertRadius: Double = 10.0
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Location Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Configure how far you want to receive alerts")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Alert Radius")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("Distance")
                            Spacer()
                            Text("\(Int(alertRadius)) km")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $alertRadius, in: 1...50, step: 1)
                            .accentColor(.blue)
                        
                        HStack {
                            Text("1 km")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("50 km")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Location")
            .navigationBarModifiers()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Notification Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Customize how you receive alerts")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    SettingRow(
                        icon: "bell.fill",
                        title: "Push Notifications",
                        subtitle: "Receive alerts and updates",
                        trailing: AnyView(Toggle("", isOn: $notificationsEnabled))
                    )
                    
                    SettingRow(
                        icon: "speaker.wave.2.fill",
                        title: "Sound",
                        subtitle: "Play sounds for alerts",
                        trailing: AnyView(Toggle("", isOn: $soundEnabled))
                    )
                    
                    SettingRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Vibration",
                        subtitle: "Vibrate for important alerts",
                        trailing: AnyView(Toggle("", isOn: $vibrationEnabled))
                    )
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Notifications")
            .navigationBarModifiers()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Privacy Settings View
struct PrivacySettingsView: View {
    @AppStorage("locationSharingEnabled") private var locationSharingEnabled = true
    @AppStorage("dataCollectionEnabled") private var dataCollectionEnabled = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Privacy Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Control your data and privacy")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    SettingRow(
                        icon: "location.fill",
                        title: "Location Sharing",
                        subtitle: "Share location for better alerts",
                        trailing: AnyView(Toggle("", isOn: $locationSharingEnabled))
                    )
                    
                    SettingRow(
                        icon: "chart.bar.fill",
                        title: "Data Collection",
                        subtitle: "Help improve the app",
                        trailing: AnyView(Toggle("", isOn: $dataCollectionEnabled))
                    )
                }
                .padding(20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Privacy")
            .navigationBarModifiers()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .frame(width: 20)
            Text(text)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
