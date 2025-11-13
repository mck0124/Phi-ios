//
//  FilterView.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI

struct FilterView: View {
    @Binding var selectedType: AlertType?
    @Environment(\.dismiss) private var dismiss
    @State private var localSelectedType: AlertType?
    
    init(selectedType: Binding<AlertType?>) {
        self._selectedType = selectedType
        self._localSelectedType = State(initialValue: selectedType.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    ForEach(AlertType.allCases) { type in
                        Button(action: {
                            localSelectedType = localSelectedType == type ? nil : type
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(Color(type.color))
                                    .frame(width: 30)
                                Text(type.rawValue)
                                Spacer()
                                if localSelectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    Text("알림 유형")
                } footer: {
                    Text("선택한 유형의 알림만 표시됩니다. 전체를 보려면 선택하지 않은 상태로 두세요.")
                }
            }
            .navigationTitle("Filter")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: leadingToolbarPlacement()) {
                    Button("Reset") {
                        localSelectedType = nil
                    }
                }
                ToolbarItem(placement: trailingToolbarPlacement()) {
                    Button("Apply") {
                        selectedType = localSelectedType
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FilterView(selectedType: .constant(nil))
}
