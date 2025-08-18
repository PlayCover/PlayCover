//
//  TouchscreenMouseEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation

// Mouse events handler when cursor is free and keyboard mapping is on

public class TouchscreenMouseEventAdapter: MouseEventAdapter {

    static public func cursorPos() -> CGPoint? {
        // IMPROVE: this is expensive (maybe?)
        var point = AKInterface.shared!.mousePoint
        let rect = AKInterface.shared!.windowFrame
        if rect.width < 1 || rect.height < 1 {
            return nil
        }
        let viewRect: CGRect = screen.screenRect
        let widthRate = viewRect.width / rect.width
        var rate = viewRect.height / rect.height
        if widthRate > rate {
            // Keep aspect ratio
            rate = widthRate
        }
        if screen.fullscreen {
            // Vertically in center
            point.y -= (rect.height - viewRect.height / rate)/2
        }
        point.y *= rate
        point.y = viewRect.height - point.y
        // For traffic light buttons when not fullscreen
        if point.y < 0 {
            return nil
        }
        // Horizontally in center
        point.x -= (rect.width - viewRect.width / rate)/2
        point.x *= rate
        return point
    }

    public func handleScrollWheel(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        _ = ActionDispatcher.dispatch(key: KeyCodeNames.scrollWheelDrag, valueX: deltaX, valueY: deltaY)
        // I dont know why but this is the logic before the refactor.
        // Might be a mistake but keeping it for now
        return false
    }

    public func handleMove(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        if ActionDispatcher.getDispatchPriority(key: KeyCodeNames.mouseMove) == .DRAGGABLE {
            // condition meets when draggable button pressed
            return ActionDispatcher.dispatch(key: KeyCodeNames.mouseMove, valueX: deltaX, valueY: -deltaY)
        } else if ActionDispatcher.getDispatchPriority(key: KeyCodeNames.fakeMouse) == .DRAGGABLE {
            // condition meets when mouse pressed and draggable button not pressed
            // fake mouse handler priority:
            // default direction pad: press handler
            // draggable direction pad: move handler
            // default button: lift handler
            // kinda hacky but.. IT WORKS!
            guard let pos = TouchscreenMouseEventAdapter.cursorPos() else { return false }
            return ActionDispatcher.dispatch(key: KeyCodeNames.fakeMouse, valueX: pos.x, valueY: pos.y)

        }
        return false
    }

    public func handleLeftButton(pressed: Bool) -> Bool {
        // It is necessary to calculate pos before pushing to dispatch queue
        // Otherwise, we don't know whether to return false or true
        guard let pos = TouchscreenMouseEventAdapter.cursorPos() else { return false }
        if pressed {
            return ActionDispatcher.dispatch(key: KeyCodeNames.fakeMouse, valueX: pos.x, valueY: pos.y)
        } else {
            return ActionDispatcher.dispatch(key: KeyCodeNames.fakeMouse, pressed: pressed)
        }
    }

    public func handleOtherButton(id: Int, pressed: Bool) -> Bool {
        ActionDispatcher.dispatch(key: EditorMouseEventAdapter.getMouseButtonName(id),
                                  pressed: pressed)
    }

    public func cursorHidden() -> Bool {
        false
    }

}
