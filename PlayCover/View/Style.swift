//
//  Style.swift
//  PlayCover
//

import Foundation
import SwiftUI

struct GetButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Colr.get)
            .foregroundColor(.white)
            .textCase(.uppercase)
            .clipShape(Capsule())
    }
}

struct UpdateButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Colr.success)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct XcodeButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

struct PlayPassButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func bgColor(_ pressed : Bool) -> Color {
        return colorScheme == .dark ? Colr.blackWhite(pressed) : Colr.blackWhite(!pressed)
    }
    
    func textColor(_ pressed : Bool) -> Color {
        return colorScheme == .dark ? Colr.blackWhite(!pressed) : Colr.blackWhite(pressed)
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(configuration.isPressed ? bgColor(false) : bgColor(true))
            .foregroundColor(configuration.isPressed ? textColor(false) : textColor(true))
            .clipShape(Capsule())
    }
}

struct GrowingButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 1.2 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct CancelButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct OutlineButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(configuration.isPressed ? .gray : .accentColor)
            .padding(.vertical, 10.0).padding(.horizontal, 10.0)
            .background(
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                ).stroke(Color.accentColor)
            )
    }
}
