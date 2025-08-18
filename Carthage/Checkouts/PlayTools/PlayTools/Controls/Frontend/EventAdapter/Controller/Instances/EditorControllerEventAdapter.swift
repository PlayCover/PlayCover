//
//  EditorControllerEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation
import GameController

// Controller events handler when in editor mode

public class EditorControllerEventAdapter: ControllerEventAdapter {
    public func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        // This is the index of controller buttons, which is String, not Int
        var alias: String = element.aliases.first!
        if alias == "Direction Pad" {
            guard let dpadElement = element as? GCControllerDirectionPad else {
                Toast.showOver(msg: "cannot map direction pad: element type not recognizable")
                return
            }
            if dpadElement.xAxis.value > 0 {
                alias = dpadElement.right.aliases.first!
            } else if dpadElement.xAxis.value < 0 {
                alias = dpadElement.left.aliases.first!
            }
            if dpadElement.yAxis.value > 0 {
                alias = dpadElement.up.aliases.first!
            } else if dpadElement.yAxis.value < 0 {
                alias = dpadElement.down.aliases.first!
            }
        }
        if alias == "Direction Pad" {
            return
        }
        EditorController.shared.setKey(alias)
    }

}
