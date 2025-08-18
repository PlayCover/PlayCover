//
//  ModeAutomaton.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/17.
//

import Foundation

// This class manages control mode transitions

public class ModeAutomaton {
    static public func onOption() -> Bool {
        if mode == .EDITOR || mode == .TEXT_INPUT {
            return false
        }
        if mode == .OFF {
            mode.set(.CAMERA_ROTATE)

        } else if mode == .ARBITRARY_CLICK && ActionDispatcher.cursorHideNecessary {
            mode.set(.CAMERA_ROTATE)

        } else if mode == .CAMERA_ROTATE {
            if PlaySettings.shared.noKMOnInput {
                mode.set(.ARBITRARY_CLICK)
            } else {
                mode.set(.OFF)
            }
        }
        // Some people want option key act as touchpad-touchscreen mapper
        return false
    }

    static public func onCmdK() {
        guard settings.keymapping else {
            return
        }

        EditorController.shared.switchMode()

        if mode == .EDITOR && !EditorController.shared.editorMode {
            mode.set(.CAMERA_ROTATE)
            ActionDispatcher.build()
            Toucher.writeLog(logMessage: "editor closed")
        } else if EditorController.shared.editorMode {
            mode.set(.EDITOR)
            Toucher.writeLog(logMessage: "editor opened")
        }
    }

    static public func onUITextInputBeginEdit() {
        if mode == .EDITOR {
            return
        }
        mode.set(.TEXT_INPUT)
    }

    static public func onUITextInputEndEdit() {
        if mode == .EDITOR {
            return
        }
        mode.set(.ARBITRARY_CLICK)
    }
}
