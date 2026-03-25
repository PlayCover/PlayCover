//
//  ViewExtensions.swift
//  PlayCover
//

import SwiftUI

extension View {
    func toastOverlay<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            return self.safeAreaBar(edge: .bottom, content: content)
        }
        #endif
        return self.overlay(content: content)
    }

    func toastBackground() -> some View {
        #if compiler(>=6.2)
        if #available(macOS 26.0, *) {
            return self.glassEffect(.regular, in: .containerRelative)
        }
        #endif
        return self.background(.regularMaterial, in: .containerRelative)
    }
}
