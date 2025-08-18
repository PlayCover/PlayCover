//
//  EditorMouseEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation

// Mouse events handler when in editor mode

public class EditorMouseEventAdapter: MouseEventAdapter {
    private static let buttonName: [String] = [
//        "InvalidMouseButton",
        KeyCodeNames.leftMouseButton,
        KeyCodeNames.rightMouseButton,
        KeyCodeNames.middleMouseButton
    ]

    public static func getMouseButtonName(_ id: Int) -> String {
        return id < EditorMouseEventAdapter.buttonName.count ?
        EditorMouseEventAdapter.buttonName[id] :
        "MBtn\(id)"
    }

    public func handleOtherButton(id: Int, pressed: Bool) -> Bool {
        if pressed {
            let name = EditorMouseEventAdapter.getMouseButtonName(id)
            // asynced to return quickly. Editor contains UI operation so main queue.
            // main queue is fine. should not be slower than keyboard
            DispatchQueue.main.async(qos: .userInteractive, execute: {
                EditorController.shared.setKey(name)
                Toucher.writeLog(logMessage: "mouse button editor set")
            })
        }
        return true
    }

    public func handleScrollWheel(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleMove(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleLeftButton(pressed: Bool) -> Bool {
        // Event flows to EditorController via UIKit
        false
    }

    public func cursorHidden() -> Bool {
        false
    }

}
