//
//  KeyboardEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation

// All keyboard events under any mode

public protocol KeyboardEventAdapter: EventAdapter {
    func handleKey(keycode: UInt16, pressed: Bool, isRepeat: Bool, ctrlModified: Bool) -> Bool
}
