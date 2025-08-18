//
//  TransparentControllerEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation
import GameController

// Controller events handler when keymap is off

public class TransparentControllerEventAdapter: ControllerEventAdapter {
    public func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        /*
         Controller event is currently handled by GameController APIs.
         This API runs concurrently with the NSEvent things.
         In other words, whatever I do in its handler, the NSEvent is not affected.
         The drawbacks of this API is, it executes through Main Dispatch Queue
         and may be delayed under high CPU pressure
         
         However, we didn't find a suitable alternative for it.
         But high CPU 3D games usually don't need to map controllers
         so it's OK for now
         */
    }
}
