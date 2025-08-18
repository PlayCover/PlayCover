//
//  TouchscreenKeyboardEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation

// Keyboard events handler when keyboard mapping is on

public class TouchscreenKeyboardEventAdapter: KeyboardEventAdapter {
    private var modifiedKeys: [UInt16] = []
    public func handleKey(keycode: UInt16, pressed: Bool, isRepeat: Bool, ctrlModified: Bool) -> Bool {

        if isRepeat {
            // eat, eat, eat!
            return true
        }

        var name = KeyCodeNames.virtualCodes[keycode] ?? "Btn"

        if keycode == 59 || keycode == 62 {
            // if this is Control
            if !pressed {
                // just in case <pressed=true, ctrl=true> followed by <pressed=false, ctrl=false>
                // release modified keys when ctrl release
                while let key = modifiedKeys.first {
                    _ = handleKey(
                        keycode: key,
                        pressed: false, isRepeat: false,
                        ctrlModified: true)
                }
            }
        } else if ctrlModified && pressed {
            name = "⌃" + name // "⌃" is not "^"
            // Record pressed key
            modifiedKeys.append(keycode)

        } else if !pressed && modifiedKeys.contains(keycode) {
            // just in case <pressed=true, ctrl=false> followed by <pressed=false, ctrl=true>
            // does not modify on release if not recorded
            name = "⌃" + name // "⌃" is not "^"
            // unrecord released key
            modifiedKeys.removeAll(where: {code in code == keycode})
        }

        return ActionDispatcher.dispatch(key: name, pressed: pressed)
    }

}
