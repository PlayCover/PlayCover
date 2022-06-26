//
//  ControlMode.swift
//  PlayTools
//

import Foundation

let mode = ControlMode.mode
    
@objc final public class ControlMode : NSObject{
    
    @objc static public let mode = ControlMode()
    
    @objc public var visible : Bool = PlaySettings.shared.gamingMode
    
    @objc static public func isMouseClick(_ event : Any) -> Bool{
        return [1,2].contains(Dynamic(event).type.asInt)
    }
    
    func show(_ show: Bool) {
        if !editor.editorMode {
            if show {
                if !visible {
                    if screen.fullscreen{
                        screen.switchDock(true)
                    }
                    if PlaySettings.shared.gamingMode {
                        Dynamic.NSCursor.unhide()
                        disableCursor(1)
                    }
                   
                    PlayInput.shared.invalidate()
                }
            } else {
                if visible{
                   
                    if PlaySettings.shared.gamingMode {
                        Dynamic.NSCursor.hide()
                        disableCursor(0)
                    }
                    if screen.fullscreen{
                        screen.switchDock(false)
                    }

                    PlayInput.shared.setup()
                }
            }
            visible = show
        }
    }
}
