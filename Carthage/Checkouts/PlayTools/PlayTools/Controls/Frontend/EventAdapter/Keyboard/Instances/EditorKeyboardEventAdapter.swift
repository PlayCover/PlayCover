//
//  EditorKeyboardEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation
import GameController

// Keyboard events handler when in editor mode

public class EditorKeyboardEventAdapter: KeyboardEventAdapter {
    private static let FORBIDDEN: [GCKeyCode] = [
        .leftGUI,
        .rightGUI,
        .leftAlt,
        .rightAlt,
        .leftControl,
        .rightControl,
        .printScreen
    ]

    public func handleKey(keycode: UInt16, pressed: Bool, isRepeat: Bool, ctrlModified: Bool) -> Bool {
        if AKInterface.shared!.cmdPressed || !pressed || isRepeat {
            return false
        }
        guard let rawValue = KeyCodeNames.mapNSEventVirtualCodeToGCKeyCodeRawValue[keycode] else {
            return false
        }
        let gcKeyCode = GCKeyCode(rawValue: rawValue)
        if EditorKeyboardEventAdapter.FORBIDDEN.contains(gcKeyCode) {
//                Toast.showHint(title: "Invalid Key", text: ["This key is intentionally forbidden. Keyname: \(name)"])
            return false
        }

        if ctrlModified {
            if let name = KeyCodeNames.virtualCodes[keycode] {
                // Setkey by name does not work with all kinds of mapping
                EditorController.shared.setKey("⌃" + name)
            }
        } else {
            EditorController.shared.setKey(rawValue)
        }

        return true
    }

}
