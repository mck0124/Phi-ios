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
    @State private var locationDescriptionText = ""
    
    init(existingAlert: Alert? = nil) {
        self.existingAlert = existingAlert
        
        if let alert = existingAlert {
            _selectedType = State(initialValue: alert.type)
            _title = State(initialValue: alert.title)
            _description = State(initialValue: alert.description ?? "")
            _locationDescriptionText = State(initialValue: alert.location.address ?? "")
        }
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
                    Text("Incident Type")
                }
                
                // Title
                Section {
                    TextField("Enter title", text: $title)
                } header: {
                    Text("Title")
                } footer: {
                    Text("Provide a short summary of the situation.")
                }
                
                // Description
                Section {
                    TextEditor(text: $description)
                        .frame(height: 100)
                } header: {
                    Text("Detailed Description")
                } footer: {
                    Text("Add as many details as possible.")
                }
                
                // Photos
                Section {
                    PhotosPicker(
                        selection: $selectedPhotosItems,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("Add Photos (up to 5)", systemImage: "photo.badge.plus")
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
                    Text("Attach supporting photos if available.")
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
                    Text("Anonymity Settings")
                } footer: {
                    Text("Choose how your report should be attributed.")
                }
                
                // Location
                Section {
                    if let location = locationManager.userLocation {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.red)
                            Text(String(format: "Lat: %.6f", location.latitude))
                            Text(String(format: "Lon: %.6f", location.longitude))
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Image(systemName: "location.slash")
                            Text("No location info")
                        }
                        .foregroundColor(.orange)
                    }
                    
                    TextField("예: 1 Queens Road, Central, Hong Kong", text: $locationDescriptionText)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                } header: {
                    Text("Location")
                } footer: {
                    Text("Your current location is used automatically.")
                }
                
                // Submit
                Section {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Report")
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
            .alert("Report Submitted", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your report has been received successfully.")
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
                longitude: userLocation.longitude,
                address: locationDescriptionText.isEmpty ? nil : locationDescriptionText
            ),
            locationDescription: locationDescriptionText,
            severity: severity,
            anonymityLevel: anonymityLevel
        )
        
        Task {
            do {
                let incidentId = existingAlert?.incidentId
                _ = try await alertService.createAlert(
                    from: input,
                    photos: selectedPhotos,
                    incidentId: incidentId
                )
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
