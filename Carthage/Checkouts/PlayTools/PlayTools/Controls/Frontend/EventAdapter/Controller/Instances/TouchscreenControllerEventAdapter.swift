//
//  TouchscreenControllerEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation
import GameController

// Controller events handler when keymap is on

public class TouchscreenControllerEventAdapter: ControllerEventAdapter {

    private var directionPadXValue: Float = 0,
                directionPadYValue: Float = 0
    static private var thumbstickCursorControl: [String: (CGFloat, CGFloat) -> Void] = [:]

    public func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        let name: String = element.aliases.first!
        if let buttonElement = element as? GCControllerButtonInput {
            _ = ActionDispatcher.dispatch(key: name, pressed: buttonElement.isPressed)
        } else if let dpadElement = element as? GCControllerDirectionPad {
            handleDirectionPad(profile, dpadElement)
        } else {
            Toast.showOver(msg: "unrecognised controller element input happens")
        }
    }

    private func handleDirectionPad(_ profile: GCExtendedGamepad, _ dpad: GCControllerDirectionPad) {
        let name = dpad.aliases.first!
        let xAxis = dpad.xAxis, yAxis = dpad.yAxis
        if name == "Direction Pad" {
            if (xAxis.value > 0) != (directionPadXValue > 0) {
                handleValueChanged(profile, dpad.right)
            }
            if (xAxis.value < 0) != (directionPadXValue < 0) {
                handleValueChanged(profile, dpad.left)
            }
            if (yAxis.value > 0) != (directionPadYValue > 0) {
                handleValueChanged(profile, dpad.up)
            }
            if (yAxis.value < 0) != (directionPadYValue < 0) {
                handleValueChanged(profile, dpad.down)
            }
            directionPadXValue = xAxis.value
            directionPadYValue = yAxis.value
            return
        }
        let deltaX = xAxis.value, deltaY = yAxis.value
        let cgDx = CGFloat(deltaX)
        let cgDy = CGFloat(deltaY)
        let dispatchType = ActionDispatcher.getDispatchPriority(key: name)
        if dispatchType == nil {
            return
        } else if dispatchType == .DEFAULT {
            _ = ActionDispatcher.dispatch(key: name, valueX: cgDx, valueY: cgDy)
        } else {
            if TouchscreenControllerEventAdapter.thumbstickCursorControl[name] == nil {
                TouchscreenControllerEventAdapter.thumbstickCursorControl[name] = ThumbstickCursorControl(name).update
            }
            TouchscreenControllerEventAdapter.thumbstickCursorControl[name]!(cgDx * 6, cgDy * 6)
        }
    }

}

class ThumbstickCursorControl {
    private var thumbstickVelocity: CGVector = CGVector.zero,
                thumbstickPolling: Bool = false,
                key: String

    init(_ key: String) {
        self.key = key
    }

    static private func isVectorSignificant(_ vector: CGVector) -> Bool {
        return vector.dx.magnitude + vector.dy.magnitude > 0.2
    }

    public func update(velocityX: CGFloat, velocityY: CGFloat) {
        self.thumbstickVelocity.dx = velocityX
        self.thumbstickVelocity.dy = velocityY
        if !thumbstickPolling {
            PlayInput.touchQueue.async(execute: self.thumbstickPoll)
            self.thumbstickPolling = true
        }
    }

    private func thumbstickPoll() {
        if !ThumbstickCursorControl.isVectorSignificant(self.thumbstickVelocity) {
            self.thumbstickPolling = false
            return
        }
        _ = ActionDispatcher.dispatch(key: key, valueX: thumbstickVelocity.dx, valueY: thumbstickVelocity.dy)
        PlayInput.touchQueue.asyncAfter(
            deadline: DispatchTime.now() + 0.017, execute: self.thumbstickPoll)
    }
}
