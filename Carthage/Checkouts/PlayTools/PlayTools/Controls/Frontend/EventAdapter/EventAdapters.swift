//
//  EventAdapters.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/15.
//

import Foundation

// This is a builder class for event adapters

public class EventAdapters {

    static func keyboard(controlMode: ControlModeLiteral) -> KeyboardEventAdapter {
        switch controlMode {
        case  .OFF, .TEXT_INPUT:
            return TransparentKeyboardEventAdapter()
        case .CAMERA_ROTATE, .ARBITRARY_CLICK:
            return TouchscreenKeyboardEventAdapter()
        case .EDITOR:
            return EditorKeyboardEventAdapter()
        }
    }

    static func mouse(controlMode: ControlModeLiteral) -> MouseEventAdapter {
        switch controlMode {
        case .OFF, .TEXT_INPUT:
            return TransparentMouseEventAdapter()
        case .CAMERA_ROTATE:
            return CameraControlMouseEventAdapter()
        case .ARBITRARY_CLICK:
            return TouchscreenMouseEventAdapter()
        case .EDITOR:
            return EditorMouseEventAdapter()
        }
    }

    static func controller(controlMode: ControlModeLiteral) -> ControllerEventAdapter {
        switch controlMode {
        case .OFF:
            return TransparentControllerEventAdapter()
        case .TEXT_INPUT, .CAMERA_ROTATE, .ARBITRARY_CLICK:
            return TouchscreenControllerEventAdapter()
        case .EDITOR:
            return EditorControllerEventAdapter()
        }
    }
}
