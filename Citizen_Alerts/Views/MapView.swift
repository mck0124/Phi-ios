//
//  MapView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var alertService = AlertService.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694), // Hong Kong coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var searchText = ""
    @State private var selectedAlert: Alert?
    @State private var showingFilterSheet = false
    @State private var showingReportSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingCommunityView = false
    @State private var showingChatView = false
    @State private var showingProfileMenu = false
    @State private var showingAlertFilterMenu = false
    @State private var filteredType: AlertType?
    @State private var isBottomMenuExpanded = false
    
    // Alert Filter Settings
    @AppStorage("alertNotificationRadius") private var notificationRadius: Double = 50.0 // km
    @AppStorage("alertMinSeverity") private var minSeverity: String = Severity.low.rawValue
    @AppStorage("alertProximityDistance") private var proximityDistance: Double = 5.0 // km - 알림을 받을 최소 거리
    @State private var selectedAlertTypes: Set<AlertType> = []
    
    var hasActiveFilters: Bool {
        filteredType != nil || !selectedAlertTypes.isEmpty || minSeverity != Severity.low.rawValue || notificationRadius != 50.0 || proximityDistance != 5.0
    }
    
    var filteredAlerts: [Alert] {
        // Start with all alerts from the service (which come from backend incidents)
        var alerts = alertService.alerts
        
        // Distance filter
        if let centerLocation = locationManager.userLocation {
            alerts = alerts.filter { alert in
                let distance = locationManager.distanceBetween(centerLocation, alert.location.coordinate)
                return distance <= notificationRadius
            }
        }
        
        // Type filter
        if let type = filteredType {
            alerts = alerts.filter { $0.type == type }
        } else if !selectedAlertTypes.isEmpty {
            alerts = alerts.filter { selectedAlertTypes.contains($0.type) }
        }
        
        // Severity filter
        if let minSeverityEnum = Severity(rawValue: minSeverity) {
            alerts = alerts.filter { severityLevel($0.severity) >= severityLevel(minSeverityEnum) }
        }
        
        return alerts.sorted { $0.createdAt > $1.createdAt }
    }
    
    private func severityLevel(_ severity: Severity) -> Int {
        switch severity {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    // TODO: Sign in 한 다음에 뒤로가기가 생기는데...? 이게 시뮬레이션이라 잇는건지 우리가 없애야되는건지 모르갰음
    var body: some View {
        NavigationView {
            ZStack {
                // 메인 지도
                Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: filteredAlerts) { alert in
                    MapAnnotation(coordinate: alert.location.coordinate) {
                        AlertMarker(alert: alert) {
                            selectedAlert = alert
                        }
                    }
                }
                .onAppear {
                    locationManager.requestPermission()
                    updateRegionToUserLocation()
                }
                .onChange(of: locationManager.userLocation?.latitude) {
                    updateRegionToUserLocation()
                }
                .onChange(of: locationManager.authorizationStatus) {
                    handleLocationPermissionChange()
                }
                .onChange(of: alertService.alerts.count) { _ in
                    // Update map when incidents are loaded from backend
                    if !filteredAlerts.isEmpty {
                        updateRegionToShowAlerts()
                    }
                }
                .ignoresSafeArea(.all, edges: [.top, .bottom])
                .sheet(item: $selectedAlert) { alert in
                    AlertDetailView(alert: alert)
                }
                
                // Loading indicator
                if alertService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(10)
                }
                
                // Error indicator
                if let error = alertService.error {
                    VStack {
                        Text("Error loading incidents")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(10)
                    .padding(.top, 100)
                }
                
                // Background overlay when menu is expanded - moved to main ZStack
                if isBottomMenuExpanded {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isBottomMenuExpanded = false
                            }
                        }
                        .zIndex(998)
                }
                
                VStack(spacing: 0) {
                    // Top Bar
                    topBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // Bottom Navigation
                    bottomNavigationBar
                }
                .zIndex(999)
                
                // Custom Bottom Sheet for Settings
                if showingSettingsSheet {
                    BottomSheet(isPresented: $showingSettingsSheet) {
                        SettingsSheetContent()
                    }
                }
                
                // Profile Menu Overlay
                if showingProfileMenu {
                    ZStack(alignment: .topTrailing) {
                        // Background overlay to dismiss menu
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                            .onTapGesture {
                                showingProfileMenu = false
                            }
                        
                        ProfileMenuView(
                            onSettings: {
                                showingProfileMenu = false
                                showingSettingsSheet = true
                            },
                            onDismiss: { showingProfileMenu = false }
                        )
                        .environmentObject(AuthManager.shared)
                        .padding(.top, 70)
                        .padding(.trailing, 20)
                    }
                    .zIndex(999)
                }
                
                // Alert Filter Menu Overlay
                if showingAlertFilterMenu {
                    ZStack {
                        // Background overlay - reduced blur for clarity
                        Color.black.opacity(0.5)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingAlertFilterMenu = false
                                }
                            }
                        
                        // Centered popup
                        AlertFilterMenuView(
                            notificationRadius: $notificationRadius,
                            minSeverity: $minSeverity,
                            proximityDistance: $proximityDistance,
                            selectedAlertTypes: $selectedAlertTypes,
                            filteredType: $filteredType,
                            onDismiss: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    showingAlertFilterMenu = false
                                }
                            }
                        )
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.92).combined(with: .opacity).combined(with: .move(edge: .bottom)),
                            removal: .scale(scale: 0.92).combined(with: .opacity)
                        ))
                        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: showingAlertFilterMenu)
                    }
                    .zIndex(1000)
                }
            }
            .task {
                await alertService.fetchAlerts()
            }
            .refreshable {
                await alertService.fetchAlerts()
            }
            .sheet(isPresented: $showingReportSheet) {
                ReportView()
            }
            .sheet(isPresented: $showingCommunityView) {
                CommunityLiveView()
            }
            .sheet(isPresented: $showingChatView) {
                ChatView()
            }
        }
    }
    
    private var topBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Hamburger Menu with glass effect
                Button(action: { showingAlertFilterMenu.toggle() }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(.primary)
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Show indicator if filters are active
                        if hasActiveFilters {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                
                // Search Bar with glass effect
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    TextField("Search location", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Account Icon with gradient
                Button(action: { showingProfileMenu.toggle() }) {
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
                        Text("M")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    private var bottomNavigationBar: some View {
        ZStack {
            // Floating action button container
            VStack {
            Spacer()
            
                ZStack {
                    // Report Button - appears on top when expanded
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isBottomMenuExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showingReportSheet = true
                        }
                    }) {
                        ZStack {
                            // Outer glow effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.red.opacity(0.4),
                                            Color.orange.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 35
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .blur(radius: 8)
                            
                            // Main button with premium gradient
                        Circle()
                            .fill(
                                LinearGradient(
                                        colors: [
                                            Color(red: 1.0, green: 0.3, blue: 0.4),
                                            Color(red: 1.0, green: 0.5, blue: 0.2),
                                            Color(red: 1.0, green: 0.4, blue: 0.3)
                                        ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                                .frame(width: 60, height: 60)
                            .overlay(
                                    // Inner highlight
                                Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .center
                                            )
                                        )
                                )
                                .overlay(
                                    // Border with gradient
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.red.opacity(0.5), radius: 15, x: 0, y: 8)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                            // Icon
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    .offset(x: 0, y: isBottomMenuExpanded ? -100 : 0)
                    .scaleEffect(isBottomMenuExpanded ? 1.0 : 0.3)
                    .opacity(isBottomMenuExpanded ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(isBottomMenuExpanded ? 0.05 : 0),
                        value: isBottomMenuExpanded
                    )
                    
                    // Community Button - appears on the left when expanded
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isBottomMenuExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showingCommunityView = true
                        }
                    }) {
                ZStack {
                            // Outer glow effect
                    Circle()
                        .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.blue.opacity(0.4),
                                            Color.purple.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 35
                                    )
                                )
                                .frame(width: 70, height: 70)
                        .blur(radius: 8)
                    
                            // Main button with premium gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                        colors: [
                                            Color(red: 0.2, green: 0.5, blue: 1.0),
                                            Color(red: 0.5, green: 0.3, blue: 0.9),
                                            Color(red: 0.4, green: 0.4, blue: 1.0)
                                        ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                                .frame(width: 60, height: 60)
                                .overlay(
                                    // Inner highlight
                    Circle()
                        .fill(
                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.3),
                                                    Color.clear
                                                ],
                                    startPoint: .topLeading,
                                                endPoint: .center
                                            )
                                )
                            )
                            .overlay(
                                    // Border with gradient
                                Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                            )
                        )
                                .shadow(color: Color.blue.opacity(0.5), radius: 15, x: 0, y: 8)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                    
                            // Icon
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    .offset(x: isBottomMenuExpanded ? -90 : 0, y: isBottomMenuExpanded ? -80 : 0)
                    .scaleEffect(isBottomMenuExpanded ? 1.0 : 0.3)
                    .opacity(isBottomMenuExpanded ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(isBottomMenuExpanded ? 0.1 : 0),
                        value: isBottomMenuExpanded
                    )
                    
                    // Chat Button - appears on the right when expanded
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isBottomMenuExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            showingChatView = true
                        }
                    }) {
            ZStack {
                            // Outer glow effect
                            Circle()
                    .fill(
                                    RadialGradient(
                            colors: [
                                            Color.green.opacity(0.4),
                                            Color.teal.opacity(0.2),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 35
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .blur(radius: 8)
                            
                            // Main button with premium gradient
                        Circle()
                            .fill(
                                LinearGradient(
                            colors: [
                                            Color(red: 0.2, green: 0.8, blue: 0.5),
                                            Color(red: 0.1, green: 0.7, blue: 0.7),
                                            Color(red: 0.2, green: 0.8, blue: 0.6)
                            ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                                .frame(width: 60, height: 60)
                            .overlay(
                                    // Inner highlight
                                Circle()
                                        .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .center
                                            )
                                        )
                                )
                                .overlay(
                                    // Border with gradient
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.green.opacity(0.5), radius: 15, x: 0, y: 8)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                            
                            // Icon
                            Image(systemName: "message.fill")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                    }
                    .offset(x: isBottomMenuExpanded ? 90 : 0, y: isBottomMenuExpanded ? -80 : 0)
                    .scaleEffect(isBottomMenuExpanded ? 1.0 : 0.3)
                    .opacity(isBottomMenuExpanded ? 1.0 : 0.0)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                        .delay(isBottomMenuExpanded ? 0.15 : 0),
                        value: isBottomMenuExpanded
                    )
                    
                    // Center Main Button - toggles menu
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isBottomMenuExpanded.toggle()
                        }
                    }) {
            ZStack {
                            // Outer glow with radial effect
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: isBottomMenuExpanded ? [
                                            Color.gray.opacity(0.5),
                                            Color.gray.opacity(0.3),
                                            Color.clear
                                        ] : [
                                            Color.red.opacity(0.5),
                                            Color.orange.opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 25,
                                        endRadius: 45
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .blur(radius: 12)
                            
                            // Secondary glow layer
                            Circle()
                    .fill(
                        LinearGradient(
                            colors: isBottomMenuExpanded ? [
                                            Color.gray.opacity(0.2),
                                            Color.gray.opacity(0.15)
                                        ] : [
                                            Color.red.opacity(0.2),
                                            Color.orange.opacity(0.15)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 85, height: 85)
                                .blur(radius: 6)
                            
                            // Main button with premium 3-color gradient
                            Circle()
                    .fill(
                        LinearGradient(
                            colors: isBottomMenuExpanded ? [
                                            Color(.systemGray4),
                                            Color(.systemGray5),
                                            Color(.systemGray3)
                            ] : [
                                            Color(red: 1.0, green: 0.25, blue: 0.35),
                                            Color(red: 1.0, green: 0.45, blue: 0.15),
                                            Color(red: 1.0, green: 0.35, blue: 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                                .frame(width: 72, height: 72)
            .overlay(
                                    // Inner highlight for depth
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.4),
                                                    Color.white.opacity(0.1),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .center
                                            )
                                        )
                                )
                                .overlay(
                                    // Premium border with gradient
                                    Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                                    Color.white.opacity(0.6),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                                            lineWidth: 2.5
                                        )
                                )
                                .shadow(color: isBottomMenuExpanded ? Color.gray.opacity(0.6) : Color.red.opacity(0.6), radius: 20, x: 0, y: 10)
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            // Icon - changes between phi and plus (rotated to X) when expanded
                            Group {
                                if isBottomMenuExpanded {
                                    Image(systemName: "plus")
                                        .font(.system(size: 34, weight: .bold))
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Text("φ")
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .frame(width: 40, height: 40, alignment: .center)
                                        .offset(y: -4)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 2)
                            .id(isBottomMenuExpanded ? "plus" : "phi")
                        }
                    }
                    .rotationEffect(.degrees(isBottomMenuExpanded ? 45 : 0))
                    .scaleEffect(isBottomMenuExpanded ? 0.95 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isBottomMenuExpanded)
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    private func updateRegionToUserLocation() {
        guard let userLocation = locationManager.userLocation else { return }
        
        withAnimation {
            region.center = userLocation
            region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        }
    }
    
    private func updateRegionToShowAlerts() {
        guard !filteredAlerts.isEmpty else { return }
        
        // Calculate bounding box for all alerts
        let latitudes = filteredAlerts.map { $0.location.coordinate.latitude }
        let longitudes = filteredAlerts.map { $0.location.coordinate.longitude }
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return }
        
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let latDelta = max(maxLat - minLat, 0.01) * 1.2 // Add 20% padding
        let lonDelta = max(maxLon - minLon, 0.01) * 1.2
        
        withAnimation {
            region.center = CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
            region.span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        }
    }
    
    private func handleLocationPermissionChange() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startLocationUpdates()
            updateRegionToUserLocation()
        case .denied, .restricted:
            // 권한이 거부된 경우 홍콩대학교로 기본 설정
            region.center = CLLocationCoordinate2D(latitude: 22.2833, longitude: 114.1378)
            region.span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        case .notDetermined:
            locationManager.requestPermission()
        @unknown default:
            break
        }
    }
}

// MARK: - Settings Sheet Content

struct SettingsSheetContent: View {
    @AppStorage("notificationsEnabled") var notificationsEnabled = true
    @AppStorage("alertRadius") var alertRadius: Double = 10.0
    @State private var showingAbout = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Notifications and app settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            
            List {
                // Notifications
                Section {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                            .frame(width: 24, height: 24)
                        Toggle("Receive notifications", isOn: $notificationsEnabled)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.green)
                                .frame(width: 24, height: 24)
                            Text("Alert radius")
                            Spacer()
                            Text("\(Int(alertRadius)) km")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.blue.opacity(0.1))
                                )
                        }
                        
                        Slider(value: $alertRadius, in: 1...50, step: 1)
                            .tint(.blue)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Notification Settings")
                        .font(.headline)
                } footer: {
                    Text("You will only receive alerts within the selected radius")
                        .font(.caption)
                }
                
                // App Info
                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.purple)
                            .frame(width: 24, height: 24)
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.gray.opacity(0.1))
                            )
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("App Information")
                        .font(.headline)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.sidebar)
            #endif
            
            // Empty space at bottom
            Color.clear
                .frame(height: 100)
        }
    }
}

// MARK: - Bottom Sheet

struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let content: Content
    @State private var dragOffset: CGFloat = 0
    
    init(isPresented: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dim with blur
                if isPresented {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                        }
                }
                
                // Bottom Sheet
                VStack {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Drag handle with modern design
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                        
                        // Content
                        content
                    }
                    .frame(height: geometry.size.height * 0.9)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            #if os(iOS)
                            .fill(Color(.systemBackground))
                            #else
                            .fill(Color(.windowBackgroundColor))
                            #endif
                            .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: -10)
                    )
                    .offset(y: isPresented ? dragOffset : geometry.size.height)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > 100 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isPresented = false
                                        dragOffset = 0
                                    }
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Alert Marker

struct AlertMarker: View {
    let alert: Alert
    let onTap: () -> Void
    
    var severityColor: Color {
        switch alert.severity {
        case .low: return Color.blue
        case .medium: return Color.green
        case .high: return Color.orange
        case .critical: return Color.red
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Pulsing animation for critical and high alerts
                if alert.severity == .critical || alert.severity == .high {
                    Circle()
                        .fill(severityColor.opacity(0.3))
                        .frame(width: 40, height: 40)
                        .scaleEffect(1.2)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: alert.severity
                        )
                }
                
                // Main icon with severity-based color
                Image(systemName: alert.type.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [severityColor, severityColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2.5)
                    )
                    .shadow(color: severityColor.opacity(0.5), radius: 8, x: 0, y: 4)
            }
            
            // Severity indicator
            if alert.severity == .critical || alert.severity == .high {
                Image(systemName: alert.severity == .critical ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(severityColor)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 14, height: 14)
                    )
                    .offset(x: 14, y: -14)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Alert Card

struct AlertCard: View {
    let alert: Alert
    let onTap: () -> Void
    
    var severityColor: Color {
        switch alert.severity {
        case .low: return Color.blue
        case .medium: return Color.green
        case .high: return Color.orange
        case .critical: return Color.red
        }
    }
    
    var severityLabel: String {
        return alert.severity.rawValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with type and severity
            HStack(spacing: 6) {
                Image(systemName: alert.type.icon)
                    .font(.caption)
                    .foregroundColor(severityColor)
                
                Text(alert.type.rawValue)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(severityColor)
                
                // Severity badge
                Text(severityLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(severityColor)
                    )
                
                Spacer()
                
                Text(timeAgo(from: alert.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            
            // Title
            Text(alert.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(.horizontal, 12)
                .padding(.top, 8)
            
            if let description = alert.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            // Footer with report count
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(alert.reportCount) reports")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if alert.isVerified {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                        Text("Verified")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 240, height: 130)
        .background(
            RoundedRectangle(cornerRadius: 16)
                #if os(iOS)
                .fill(Color(.systemBackground))
                #else
                .fill(Color(.windowBackgroundColor))
                #endif
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [severityColor.opacity(0.3), severityColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onTap()
            }
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Profile Menu View
struct ProfileMenuView: View {
    let onSettings: () -> Void
    let onDismiss: () -> Void
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Profile Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text("M")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Citizen User")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Active Member")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(16)
            
            Divider()
            
            // Menu Items
            VStack(spacing: 0) {
                ProfileMenuItem(
                    icon: "gearshape.fill",
                    title: "Settings",
                    color: .gray
                ) {
                    onSettings()
                }
                
                ProfileMenuItem(
                    icon: "person.fill",
                    title: "Profile",
                    color: .blue
                ) {
                    // Profile action - can be implemented later
                    onDismiss()
                }
                
                ProfileMenuItem(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    color: .green
                ) {
                    // Help action - can be implemented later
                    onDismiss()
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                ProfileMenuItem(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Log Out",
                    color: .red
                ) {
                    authManager.logout()
                    onDismiss()
                }
            }
        }
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Alert Filter Menu View
import SwiftUI

struct AlertFilterMenuView: View {
    @Binding var notificationRadius: Double
    @Binding var minSeverity: String
    @Binding var proximityDistance: Double
    @Binding var selectedAlertTypes: Set<AlertType>
    @Binding var filteredType: AlertType?
    let onDismiss: () -> Void

    // MARK: - Theme
    private let corner: CGFloat = 22
    private let cardPadding: CGFloat = 16

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Header - Compact Design
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(Color(.systemBackground))

                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                        
                        Text("Alert Filters")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                                resetFilters()
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 28, height: 28)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.primary)
                                .frame(width: 28, height: 28)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .frame(height: 52)

            // MARK: Content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {

                    // Notification Radius
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Notification Radius", subtitle: "Receive alerts within this distance")
                            HStack(alignment: .lastTextBaseline, spacing: 6) {
                                GradientNumber(
                                    text: "\(Int(notificationRadius))",
                                    gradient: LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                                )
                                Text("km")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $notificationRadius, in: 1...100, step: 1)
                                .tint(.blue)
                            HBound(min: "1 km", max: "100 km")
                        }
                        .padding(cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityLabel("Notification Radius")

                    // Minimum Severity
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Minimum Severity", subtitle: "Only show alerts with this severity or higher")
                            SeverityPills(
                                current: minSeverity,
                                onSelect: { s in
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.25)) {
                                        minSeverity = s.rawValue
                                    }
                                }
                            )
                        }
                        .padding(cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityLabel("Minimum Severity")

                    // Proximity Alert
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Proximity Alert", subtitle: "Get notified when you're this close")
                            HStack(alignment: .lastTextBaseline, spacing: 6) {
                                GradientNumber(
                                    text: String(format: "%.1f", proximityDistance),
                                    gradient: LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                )
                                Text("km")
                                    .font(.title3.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $proximityDistance, in: 0.5...20, step: 0.5)
                                .tint(.red)
                            HBound(min: "0.5 km", max: "20 km")
                        }
                        .padding(cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityLabel("Proximity Alert")

                    // Alert Types
                    GlassCard {
                        VStack(alignment: .leading, spacing: 14) {
                            SectionHeader(title: "Alert Types", subtitle: "Select types to show (leave empty for all)")
                            FlexibleChipGrid(items: Array(AlertType.allCases)) { type in
                                let selected = selectedAlertTypes.contains(type)
                                Chip(
                                    title: type.rawValue,
                                    icon: type.icon,
                                    tint: type.uiColor,
                                    selected: selected
                                ) {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    withAnimation(.spring(response: 0.25)) {
                                        if selected { selectedAlertTypes.remove(type) }
                                        else { selectedAlertTypes.insert(type) }
                                    }
                                }
                            }
                        }
                        .padding(cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityLabel("Alert Types")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }

            // MARK: Bottom action bar - Removed for cleaner design
        }
        .frame(width: 350)
        .frame(maxHeight: 600)
        .background(
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(
                    // More opaque background for better clarity
                    Color(.systemBackground)
                        .opacity(0.98)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 50, x: 0, y: 25)
        )
        .compositingGroup()
    }

    // MARK: - Actions
    private func resetFilters() {
        notificationRadius = 50.0
        minSeverity = Severity.low.rawValue
        proximityDistance = 5.0
        selectedAlertTypes = []
        filteredType = nil
    }
}

// MARK: - Components

private struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    // More opaque white background for clarity
                    Color(.secondarySystemBackground)
                        .opacity(0.95)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary.opacity(0.9))
        }
    }
}

private struct GradientNumber: View {
    let text: String
    let gradient: LinearGradient
    var body: some View {
        Text(text)
            .font(.system(size: 44, weight: .black, design: .rounded))
            .foregroundStyle(gradient)
            .minimumScaleFactor(0.6)
            .lineLimit(1)
    }
}

private struct HBound: View {
    let min: String
    let max: String
    var body: some View {
        HStack {
            Text(min).font(.caption2).foregroundStyle(.secondary)
            Spacer()
            Text(max).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

private struct CircleButton: View {
    let icon: String
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 34, height: 34)
            .background(Color.white.opacity(0.18))
            .clipShape(Circle())
            .overlay(
                Circle().stroke(.white.opacity(0.25), lineWidth: 1)
            )
    }
}

private struct GlassButtonStyle: ButtonStyle {
    let tint: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(configuration.isPressed ? 0.28 : 0.32))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.white.opacity(configuration.isPressed ? 0.18 : 0.28), lineWidth: 1)
                    )
            )
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Severity Pills

private struct SeverityPills: View {
    let current: String
    let onSelect: (Severity) -> Void

    private let severities: [Severity] = [.low, .medium, .high, .critical]

    var body: some View {
        FlexibleChipGrid(items: severities) { s in
            let isOn = current == s.rawValue
            Pill(title: s.rawValue,
                 icon: "exclamationmark.triangle.fill",
                 tint: s.uiColor,
                 selected: isOn) {
                onSelect(s)
            }
        }
    }
}

// MARK: - Generic Chip/Pill

private struct Pill: View {
    let title: String
    let icon: String
    let tint: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        selected 
                        ? LinearGradient(
                            colors: [tint, tint.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule(style: .continuous).stroke(
                            selected
                            ? LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                    )
            )
            .foregroundStyle(selected ? .white : .primary)
            .shadow(color: selected ? tint.opacity(0.5) : Color.clear, radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct Chip: View {
    let title: String
    let icon: String
    let tint: Color
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Pill(title: title, icon: icon, tint: tint, selected: selected, action: action)
    }
}

// MARK: - Flexible grid for chips

private struct FlexibleChipGrid<Item: Hashable, Content: View>: View {
    let items: [Item]
    @ViewBuilder var content: (Item) -> Content

    // 2열 이상으로 자동 줄바꿈
    private let columns = [
        GridItem(.flexible(minimum: 80), spacing: 10),
        GridItem(.flexible(minimum: 80), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(items, id: \.self) { item in
                content(item)
            }
        }
    }
}

// MARK: - Modern Filter Components
struct FilterCard<Content: View>: View {
    let icon: String
    let iconColor: Color
    let gradient: LinearGradient
    let content: Content
    
    init(icon: String, iconColor: Color, gradient: LinearGradient, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.iconColor = iconColor
        self.gradient = gradient
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(iconColor.opacity(0.15))
                    )
                Spacer()
            }
            .padding(.bottom, 12)
            
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)
                
                // Progress
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 6)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width - 10)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let percentage = max(0, min(1, gesture.location.x / geometry.size.width))
                        let newValue = range.lowerBound + Double(percentage) * (range.upperBound - range.lowerBound)
                        value = round(newValue / step) * step
                    }
            )
        }
        .frame(height: 20)
    }
}

struct ModernFilterButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModernToggleButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(isSelected ? color : color.opacity(0.15))
                    )
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 2)
            )
            .shadow(color: isSelected ? color.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    MapView()
}
