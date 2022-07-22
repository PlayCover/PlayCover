//
//  Colors.swift
//  PlayCover
//

import Foundation
import SwiftUI

extension Color {

    init(hex: UInt, alpha: Double = 1) {
           self.init(
               .sRGB,
               red: Double((hex >> 16) & 0xff) / 255,
               green: Double((hex >> 08) & 0xff) / 255,
               blue: Double((hex >> 00) & 0xff) / 255,
               opacity: alpha
           )
       }
}

class Colr {

    static func control(_ darkMode: Bool = isDarkMode()) -> Color {
        if darkMode {
            return Color.init(hex: 0x292729)
        }
        return Color.init(hex: 0xe6e2e3)
    }

    static func controlSelect(_ darkMode: Bool = isDarkMode()) -> Color {
        if darkMode {
            return Color.init(hex: 0x423f41)
        }
        return Color.init(hex: 0xcfcacb)
    }

    static func highlighted(_ darkMode: Bool = isDarkMode()) -> Color {
        if darkMode {
            return Color.init(hex: 0x857E82)
        }
        return Color.init(hex: 0x827F80)
    }

    static func text(_ darkMode: Bool = isDarkMode()) -> Color {
        if darkMode {
            return Color.init(hex: 0xececec)
        }
        return Color.init(hex: 0x444344)
    }

    static let error: Color = Color.init(hex: 0xFF5733)

    static let success: Color = Color.init(hex: 0x2ECC71)

    static func blackWhite(_ reversed: Bool) -> Color {
        if reversed {
            return Color.init(hex: 0xffffff)
        }
        return Color.init(hex: 0x000000)
    }

    static let accent: Color = Color.init(hex: 0xB02AF5)

    static let primary: Color = Color.init(hex: 0xFF0066)

    static let get: Color = Color.init(hex: 0xff4d94)

    static func isDarkMode() -> Bool {
        return NSApp.effectiveAppearance
            .bestMatch(from: [NSAppearance.Name.aqua, NSAppearance.Name.darkAqua]) == NSAppearance.Name.darkAqua
    }
}
