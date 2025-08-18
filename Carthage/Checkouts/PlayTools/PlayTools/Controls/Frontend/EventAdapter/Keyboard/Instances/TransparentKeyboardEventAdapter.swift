//
//  TextInputKeyboardEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation

// Keyboard events handler when keyboard mapping is off

public class TransparentKeyboardEventAdapter: KeyboardEventAdapter {
    public func handleKey(keycode: UInt16, pressed: Bool, isRepeat: Bool, ctrlModified: Bool) -> Bool {
        // explicitly eat repeated Enter key
        isRepeat && keycode == 36
    }

}
