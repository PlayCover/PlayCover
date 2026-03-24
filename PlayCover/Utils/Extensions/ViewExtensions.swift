//
//  ViewExtensions.swift
//  PlayCover
//

import SwiftUI

extension View {
    @ViewBuilder
    func toastOverlay<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        if #available(macOS 26.0, *) {
            self.safeAreaBar(edge: .bottom) {
                content()
            }
        } else {
            self.overlay {
                content()
            }
        }
    }

    @ViewBuilder
    func toastBackground() -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(.regular, in:
                                ContainerRelativeShape())
        } else {
            self.background(.regularMaterial, in:
                                ContainerRelativeShape())
        }
    }
}
