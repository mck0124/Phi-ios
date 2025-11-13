//
//  PlatformHelpers.swift
//  Citizen Alerts
//
//  Created by Minchan Kim on 10/25/25.
//

import SwiftUI

extension Color {
    static var adaptiveGray: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color.gray.opacity(0.1)
        #endif
    }
    
    static var adaptiveGray5: Color {
        #if os(iOS)
        return Color(.systemGray5)
        #else
        return Color.gray.opacity(0.15)
        #endif
    }
}

extension View {
    @ViewBuilder
    func navigationBarModifiers() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func toolbarButton(placement: ToolbarItemPlacement = .automatic, @ViewBuilder content: () -> some View) -> some View {
        toolbar {
            ToolbarItem(placement: placement) {
                content()
            }
        }
    }
}

// Helper functions to get navigation placement
func trailingToolbarPlacement() -> ToolbarItemPlacement {
    #if os(iOS)
    return .navigationBarTrailing
    #else
    return .automatic
    #endif
}

func leadingToolbarPlacement() -> ToolbarItemPlacement {
    #if os(iOS)
    return .navigationBarLeading
    #else
    return .automatic
    #endif
}
