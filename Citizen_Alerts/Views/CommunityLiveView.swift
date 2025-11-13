//
//  CommunityLiveView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/31/25.
//

import SwiftUI

struct CommunityLiveView: View {
    @State private var selectedTab: CommunityTab = .live
    @State private var selectedEvent: CommunityEvent?
    @StateObject private var locationManager = LocationManager.shared
    
    enum CommunityTab: String, CaseIterable {
        case live = "Live"
        case recap = "Recap"
        case myPage = "My Page"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Tab Bar
                tabBarSection
                
                // Content based on selected tab
                ScrollView {
                    VStack(spacing: 28) {
                        if selectedTab == .live {
                            liveContent
                        } else if selectedTab == .recap {
                            recapContent
                        } else {
                            myPageContent
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $selectedEvent) { event in
            CommunityEventDetailView(event: event)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Live Updates")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formatDate(Date()))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // User Avatar
                Button(action: {}) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Text("M")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .background(
            Color(.systemBackground)
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator)),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Tab Bar
    private var tabBarSection: some View {
        HStack(spacing: 32) {
            ForEach(CommunityTab.allCases, id: \.self) { tab in
                VStack(spacing: 4) {
                    Text(tab.rawValue)
                        .font(.headline)
                        .foregroundColor(selectedTab == tab ? .primary : .secondary)
                    
                    if selectedTab == tab {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: 2)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 2)
                    }
                }
                .onTapGesture {
                    withAnimation {
                        selectedTab = tab
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Live Content
    private var liveContent: some View {
        VStack(spacing: 24) {
            // Happening Nearby Section
            happeningNearbySection
            
            // Be the Alert Section
            beTheAlertSection
        }
    }
    
    // MARK: - Happening Nearby Section
    private var happeningNearbySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Happening Nearby")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.bottom, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(happeningNearbyEvents) { event in
                        CommunityEventCard(event: event, style: .nearby) {
                            selectedEvent = event
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Be the Alert Section
    private var beTheAlertSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Be the Alert!")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 16) {
                ForEach(beTheAlertEvents) { event in
                    CommunityEventCard(event: event, style: .alert) {
                        selectedEvent = event
                    }
                }
            }
        }
    }
    
    // MARK: - Recap Content
    private var recapContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Today's Recap")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.bottom, 4)
            
            VStack(spacing: 16) {
                ForEach(allEvents.prefix(5)) { event in
                    CommunityEventCard(event: event, style: .recap) {
                        selectedEvent = event
                    }
                }
            }
        }
    }
    
    // MARK: - My Page Content
    private var myPageContent: some View {
        VStack(spacing: 28) {
            // Profile Section
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Text("M")
                        .font(.system(size: 48))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 8) {
                    Text("Citizen User")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Active Member")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 24)
            
            // Stats Section
            HStack(spacing: 32) {
                StatCard(title: "Reports", value: "12")
                StatCard(title: "Verified", value: "8")
                StatCard(title: "Contributions", value: "24")
            }
            
            // My Reports
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("My Reports")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.bottom, 4)
                
                VStack(spacing: 16) {
                    ForEach(userReports) { event in
                        CommunityEventCard(event: event, style: .recap) {
                            selectedEvent = event
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sample Data
    private var happeningNearbyEvents: [CommunityEvent] {
        allEvents.filter { $0.credibility >= .medium && $0.reportCount >= 5 }
    }
    
    private var beTheAlertEvents: [CommunityEvent] {
        allEvents.filter { $0.credibility == .low && $0.reportCount <= 3 }
    }
    
    private var userReports: [CommunityEvent] {
        allEvents.filter { $0.isUserReport }
    }
    
    private var allEvents: [CommunityEvent] {
        CommunityEvent.sampleEvents
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Community Event Model
struct CommunityEvent: Identifiable {
    let id: UUID
    let title: String
    let location: String
    let distance: Double
    let reportCount: Int
    let firstReportTime: Date
    let credibility: CredibilityLevel
    let imageName: String
    let isUserReport: Bool
    let description: String?
    
    enum CredibilityLevel: Comparable {
        case low
        case medium
        case high
        
        var label: String {
            switch self {
            case .high: return "Credible"
            case .medium: return "Developing"
            case .low: return "Unverified"
            }
        }
        
        var color: Color {
            switch self {
            case .high: return .green
            case .medium: return .orange
            case .low: return .red
            }
        }
    }
    
    static var sampleEvents: [CommunityEvent] {
        let now = Date()
        return [
            CommunityEvent(
                id: UUID(),
                title: "Fire breakout in Central",
                location: "Chinachem Tower, Connaught Rd Central, Central",
                distance: 1.2,
                reportCount: 34,
                firstReportTime: now.addingTimeInterval(-3600),
                credibility: .high,
                imageName: "fire",
                isUserReport: false,
                description: "Large fire reported in Central district. Multiple fire trucks on scene."
            ),
            CommunityEvent(
                id: UUID(),
                title: "Imminent Protest Gathering",
                location: "Admiralty, Hong Kong",
                distance: 1.7,
                reportCount: 6,
                firstReportTime: now.addingTimeInterval(-2700),
                credibility: .medium,
                imageName: "protest",
                isUserReport: false,
                description: "Crowd gathering reported. Authorities monitoring situation."
            ),
            CommunityEvent(
                id: UUID(),
                title: "Earthquake in Admiralty",
                location: "Chinachem Tower, Connaught Rd Central, Central",
                distance: 1.8,
                reportCount: 1,
                firstReportTime: now.addingTimeInterval(-1200),
                credibility: .low,
                imageName: "earthquake",
                isUserReport: true,
                description: "Possible earthquake tremor felt in Admiralty area."
            ),
            CommunityEvent(
                id: UUID(),
                title: "Traffic Accident on Highway",
                location: "Tsim Sha Tsui Road",
                distance: 2.3,
                reportCount: 12,
                firstReportTime: now.addingTimeInterval(-1800),
                credibility: .high,
                imageName: "traffic",
                isUserReport: false,
                description: "Multi-vehicle collision causing traffic delays."
            ),
            CommunityEvent(
                id: UUID(),
                title: "Suspicious Activity Reported",
                location: "Wan Chai District",
                distance: 3.1,
                reportCount: 2,
                firstReportTime: now.addingTimeInterval(-900),
                credibility: .low,
                imageName: "crime",
                isUserReport: false,
                description: "Unverified report of suspicious activity."
            ),
            CommunityEvent(
                id: UUID(),
                title: "Medical Emergency",
                location: "Central Park, Central",
                distance: 1.5,
                reportCount: 8,
                firstReportTime: now.addingTimeInterval(-1500),
                credibility: .medium,
                imageName: "medical",
                isUserReport: true,
                description: "Medical assistance required at Central Park."
            )
        ]
    }
}

// MARK: - Community Event Card
struct CommunityEventCard: View {
    let event: CommunityEvent
    let style: CardStyle
    let action: () -> Void
    
    enum CardStyle {
        case nearby  // Horizontal scrollable cards
        case alert   // Vertical list cards
        case recap   // Recap view cards
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Image with credibility badge
                ZStack(alignment: .bottomLeading) {
                    // Placeholder image
                    RoundedRectangle(cornerRadius: style == .nearby ? 12 : 16)
                        .fill(
                            LinearGradient(
                                colors: eventImageGradient(for: event.imageName),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(
                            width: style == .nearby ? 280 : nil,
                            height: style == .nearby ? 180 : 200
                        )
                    
                    // Credibility Badge
                    if event.credibility == .high {
                        Text(event.credibility.label)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(event.credibility.color)
                            .cornerRadius(20)
                            .padding(12)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(event.location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Text("\(String(format: "%.1f", event.distance)) km away")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption2)
                            Text("\(event.reportCount)")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Spacer()
                        Text("First Report: \(formatTime(event.firstReportTime))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(12)
                .frame(width: style == .nearby ? 280 : nil)
            }
            .background(Color(.systemGray6))
            .cornerRadius(style == .nearby ? 12 : 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func eventImageGradient(for imageName: String) -> [Color] {
        switch imageName {
        case "fire":
            return [.red.opacity(0.6), .orange.opacity(0.4)]
        case "protest":
            return [.blue.opacity(0.5), .purple.opacity(0.4)]
        case "earthquake":
            return [.gray.opacity(0.5), .brown.opacity(0.4)]
        case "traffic":
            return [.yellow.opacity(0.5), .orange.opacity(0.4)]
        case "crime":
            return [.purple.opacity(0.5), .pink.opacity(0.4)]
        case "medical":
            return [.red.opacity(0.5), .pink.opacity(0.4)]
        default:
            return [.blue.opacity(0.4), .cyan.opacity(0.3)]
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Community Event Detail View
struct CommunityEventDetailView: View {
    let event: CommunityEvent
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(
                                LinearGradient(
                                    colors: eventImageGradient(for: event.imageName),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 250)
                        
                        if event.credibility == .high {
                            Text(event.credibility.label)
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(event.credibility.color)
                                .cornerRadius(20)
                                .padding(20)
                        }
                    }
                    .ignoresSafeArea()
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 16) {
                            Label("\(String(format: "%.1f", event.distance)) km away", systemImage: "location.fill")
                            Label("\(event.reportCount) reports", systemImage: "exclamationmark.triangle.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        Text(event.location)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if let description = event.description {
                            Text(description)
                                .font(.body)
                                .padding(.top, 8)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("First Reported:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDate(event.firstReportTime))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Event Details")
            .navigationBarModifiers()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func eventImageGradient(for imageName: String) -> [Color] {
        switch imageName {
        case "fire":
            return [.red.opacity(0.6), .orange.opacity(0.4)]
        case "protest":
            return [.blue.opacity(0.5), .purple.opacity(0.4)]
        case "earthquake":
            return [.gray.opacity(0.5), .brown.opacity(0.4)]
        case "traffic":
            return [.yellow.opacity(0.5), .orange.opacity(0.4)]
        case "crime":
            return [.purple.opacity(0.5), .pink.opacity(0.4)]
        case "medical":
            return [.red.opacity(0.5), .pink.opacity(0.4)]
        default:
            return [.blue.opacity(0.4), .cyan.opacity(0.3)]
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    CommunityLiveView()
}

