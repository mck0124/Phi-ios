//
//  AlertsListView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI

struct AlertsListView: View {
    @StateObject private var alertService = AlertService.shared
    @StateObject private var locationManager = LocationManager.shared
    @State private var selectedAlert: Alert?
    @State private var searchText = ""
    @State private var selectedType: AlertType?
    @State private var sortOption: SortOption = .recent
    
    enum SortOption: String, CaseIterable {
        case recent = "최신순"
        case distance = "거리순"
        case severity = "심각도순"
    }
    
    var filteredAlerts: [Alert] {
        var alerts = alertService.alerts
        
        // Type filter
        if let selectedType = selectedType {
            alerts = alerts.filter { $0.type == selectedType }
        }
        
        // Search filter
        if !searchText.isEmpty {
            alerts = alerts.filter { alert in
                alert.title.localizedCaseInsensitiveContains(searchText) ||
                alert.description?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        // Sort alerts
        return sortAlerts(alerts)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                searchBar
                
                // Type filter chips
                typeFilterChips
                
                // Alerts list
                if filteredAlerts.isEmpty {
                    emptyState
                } else {
                    alertsList
                }
            }
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: trailingToolbarPlacement()) {
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(action: { sortOption = option }) {
                                HStack {
                                    Text(option.rawValue)
                                    if sortOption == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
            .sheet(item: $selectedAlert) { alert in
                AlertDetailView(alert: alert)
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("검색...", text: $searchText)
        }
        .padding()
        .background(Color.adaptiveGray)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    private var typeFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", isSelected: selectedType == nil) {
                    selectedType = nil
                }
                
                ForEach(AlertType.allCases) { type in
                    FilterChip(
                        title: type.rawValue,
                        isSelected: selectedType == type,
                        color: Color(type.color)
                    ) {
                        selectedType = selectedType == type ? nil : type
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("No Alerts")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("No alerts nearby or try adjusting filter conditions")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var alertsList: some View {
        List(filteredAlerts) { alert in
            AlertRowView(alert: alert) {
                selectedAlert = alert
            }
        }
        .listStyle(.plain)
    }
    
    private func sortAlerts(_ alerts: [Alert]) -> [Alert] {
        switch sortOption {
        case .recent:
            return alerts.sorted { $0.createdAt > $1.createdAt }
        case .distance:
            return sortByDistance(alerts)
        case .severity:
            return sortBySeverity(alerts)
        }
    }
    
    private func sortByDistance(_ alerts: [Alert]) -> [Alert] {
        guard let userLocation = locationManager.userLocation else {
            return alerts.sorted { $0.createdAt > $1.createdAt }
        }
        
        return alerts.sorted { alert1, alert2 in
            let distance1 = locationManager.distanceBetween(userLocation, alert1.location.coordinate)
            let distance2 = locationManager.distanceBetween(userLocation, alert2.location.coordinate)
            return distance1 < distance2
        }
    }
    
    private func sortBySeverity(_ alerts: [Alert]) -> [Alert] {
        let severityOrder: [Severity] = [.critical, .high, .medium, .low]
        
        return alerts.sorted { alert1, alert2 in
            let index1 = severityOrder.firstIndex(of: alert1.severity) ?? 0
            let index2 = severityOrder.firstIndex(of: alert2.severity) ?? 0
            
            if index1 == index2 {
                // 같은 심각도면 최신순으로
                return alert1.createdAt > alert2.createdAt
            }
            return index1 < index2
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : Color.adaptiveGray5)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct AlertRowView: View {
    let alert: Alert
    let onTap: () -> Void
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: alert.type.icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(Color(alert.type.color))
                .cornerRadius(10)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(timeAgo(from: alert.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let description = alert.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label("\(alert.reportCount)명", systemImage: "person.2.fill")
                    Spacer()
                    if let distance = distanceToAlert {
                        Text(String(format: "%.1fkm", distance))
                            .foregroundColor(.blue)
                    }
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    private var distanceToAlert: Double? {
        guard let userLocation = locationManager.userLocation else { return nil }
        return locationManager.distanceBetween(userLocation, alert.location.coordinate)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    AlertsListView()
}
