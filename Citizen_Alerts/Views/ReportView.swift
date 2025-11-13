//
//  ReportView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI
import PhotosUI
#if os(iOS)
import UIKit
#endif

struct ReportView: View {
    let existingAlert: Alert?
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var alertService = AlertService.shared
    @StateObject private var locationManager = LocationManager.shared
    
    @State private var selectedType: AlertType = .other
    @State private var title = ""
    @State private var description = ""
    @State private var selectedPhotos: [AlertPhoto] = []
    @State private var selectedPhotosItems: [PhotosPickerItem] = []
    @State private var severity: Severity = .medium
    @State private var anonymityLevel: AnonymityLevel = .anonymous
    @State private var showingImagePicker = false
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    
    init(existingAlert: Alert? = nil) {
        self.existingAlert = existingAlert
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Type Selection
                Section {
                    Picker("Incident Type", selection: $selectedType) {
                        ForEach(AlertType.allCases) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                } header: {
                    Text("사고 유형")
                }
                
                // Title
                Section {
                    TextField("제목 입력", text: $title)
                } header: {
                    Text("Title")
                } footer: {
                    Text("간단하게 상황을 설명해주세요")
                }
                
                // Description
                Section {
                    TextEditor(text: $description)
                        .frame(height: 100)
                } header: {
                    Text("상세 설명")
                } footer: {
                    Text("자세한 내용을 입력해주세요")
                }
                
                // Photos
                Section {
                    PhotosPicker(
                        selection: $selectedPhotosItems,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("사진 추가 (최대 5장)", systemImage: "photo.badge.plus")
                    }
                    
                    if !selectedPhotos.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(selectedPhotos) { photo in
                                    #if os(iOS)
                                    if let image = UIImage(data: photo.imageData) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .cornerRadius(8)
                                            .overlay(
                                                Button(action: {
                                                    removePhoto(photo)
                                                }) {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.red)
                                                        .background(Color.white)
                                                        .clipShape(Circle())
                                                }
                                                .padding(4),
                                                alignment: .topTrailing
                                            )
                                    }
                                    #else
                                    Image(systemName: "photo")
                                        .frame(width: 100, height: 100)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                    #endif
                                }
                            }
                        }
                    }
                } header: {
                    Text("Photos")
                } footer: {
                    Text("증거 사진을 추가해주세요")
                }
                
                // Severity
                Section {
                    Picker("Severity", selection: $severity) {
                        ForEach([Severity.low, .medium, .high, .critical], id: \.self) { sev in
                            Text(sev.rawValue).tag(sev)
                        }
                    }
                } header: {
                    Text("Severity")
                }
                
                // Anonymity
                Section {
                    Picker("Anonymity", selection: $anonymityLevel) {
                        ForEach(AnonymityLevel.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                } header: {
                    Text("익명 설정")
                } footer: {
                    Text("신고 시 익명 레벨을 선택하세요")
                }
                
                // Location
                Section {
                    if let location = locationManager.userLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            Text(String(format: "위도: %.6f", location.latitude))
                            Text(String(format: "경도: %.6f", location.longitude))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Image(systemName: "location.slash")
                            Text("위치 정보 없음")
                        }
                        .foregroundColor(.orange)
                    }
                } header: {
                    Text("Location")
                } footer: {
                    Text("자동으로 현재 위치가 사용됩니다")
                }
                
                // Submit
                Section {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("신고 제출")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(title.isEmpty || isSubmitting || locationManager.userLocation == nil)
                }
            }
            .navigationTitle(existingAlert == nil ? "Report Incident" : "Re-report")
            .toolbar {
                ToolbarItem(placement: leadingToolbarPlacement()) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhotosItems) { newItems in
                loadPhotos(from: newItems)
            }
            .alert("신고 완료", isPresented: $showSuccessAlert) {
                Button("Submit") {
                    dismiss()
                }
            } message: {
                Text("신고가 성공적으로 접수되었습니다.")
            }
        }
    }
    
    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let photo = AlertPhoto(imageData: data)
                    await MainActor.run {
                        selectedPhotos.append(photo)
                    }
                }
            }
        }
    }
    
    private func removePhoto(_ photo: AlertPhoto) {
        selectedPhotos.removeAll { $0.id == photo.id }
    }
    
    private func submitReport() {
        guard let userLocation = locationManager.userLocation else { return }
        
        isSubmitting = true
        
        let input = AlertInput(
            type: selectedType,
            title: title,
            description: description,
            photos: selectedPhotos,
            location: LocationData(
                latitude: userLocation.latitude,
                longitude: userLocation.longitude
            ),
            severity: severity,
            anonymityLevel: anonymityLevel
        )
        
        Task {
            do {
                if let existingAlert = existingAlert {
                    // Increment report count for existing alert
                    try await alertService.incrementReportCount(for: existingAlert.id)
                } else {
                    // Create new alert
                    _ = try await alertService.createAlert(from: input, photos: selectedPhotos)
                }
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    print("Error submitting report: \(error)")
                }
            }
        }
    }
}

#Preview {
    ReportView()
}
