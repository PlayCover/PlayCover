//
//  PlayAction.swift
//  PlayTools
//

import Foundation
import GameController

protocol Action{
    func invalidate()
}

extension GCKeyboard {
    static func pressed(key : GCKeyCode) -> Bool{
        return GCKeyboard.coalesced?.keyboardInput?.button(forKeyCode: key)?.isPressed ?? false
    }
}

class ButtonAction : Action {
    
    func invalidate() {
        Toucher.touchcam(point: point, phase: UITouch.Phase.ended, tid: id)
    }
    
    let key : GCKeyCode
    let keyid : Int
    let point : CGPoint
    var id : Int
    
    init(id: Int, keyid: Int, key : GCKeyCode, point : CGPoint){
        self.keyid = keyid
        self.key = key
        self.point = point
        self.id = id
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            if !PlayMice.shared.setMiceButtons(keyid, action: self){
                keyboard.button(forKeyCode: key)?.pressedChangedHandler = { (key, keyCode, pressed) in
                    if !mode.visible {
                        self.update(pressed: pressed)
                    }
                }
            }
        }
    }
    
    func update(pressed : Bool){
        if(pressed){
            Toucher.touchcam(point: point, phase: UITouch.Phase.began, tid: id)
        } else {
            Toucher.touchcam(point: point, phase: UITouch.Phase.ended, tid: id)
        }
    }
}

class JoystickAction : Action {
    
    let keys : [GCKeyCode]
    let center: CGPoint
    let shift: CGFloat
    var id : Int
    var moving = false
    
    init(id: Int, keys : [GCKeyCode], center : CGPoint, shift : CGFloat){
        self.keys = keys
        self.center = center
        self.shift = shift / 2
        self.id = id
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            keyboard.button(forKeyCode: keys[0])?.pressedChangedHandler = { (key, keyCode, pressed) in
                self.update()
            }
            keyboard.button(forKeyCode: keys[1])?.pressedChangedHandler = { (key, keyCode, pressed) in
                self.update()
            }
            keyboard.button(forKeyCode: keys[2])?.pressedChangedHandler = { (key, keyCode, pressed) in
                self.update()
            }
            keyboard.button(forKeyCode: keys[3])?.pressedChangedHandler = { (key, keyCode, pressed) in
                self.update()
            }
        }
    }
    
    func invalidate(){
        Toucher.touchcam(point: center, phase: UITouch.Phase.ended, tid: id)
        self.moving = false
    }
    
    func update(){
        if !mode.visible {
            var touch = center
            if(GCKeyboard.pressed(key: keys[0])){
                touch.y = touch.y - shift / 3
            } else if(GCKeyboard.pressed(key: keys[1])){
                touch.y = touch.y + shift / 3
            }
            if(GCKeyboard.pressed(key: keys[2])){
                touch.x = touch.x - shift / 3
            } else if(GCKeyboard.pressed(key: keys[3])){
                touch.x = touch.x + shift / 3
            }
            if(moving){
                if(touch.equalTo(center)){
                    moving = false
                    Toucher.touchcam(point: touch, phase: UITouch.Phase.cancelled, tid: id)
                } else{
                    Toucher.touchcam(point: touch, phase: UITouch.Phase.moved, tid: id)
                }
            } else{
                moving = true
                Toucher.touchcam(point: self.center, phase: UITouch.Phase.began, tid: id)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                    Toucher.touchcam(point: touch, phase: UITouch.Phase.moved, tid: self.id)
                }
               
            }
        }
    }
}
