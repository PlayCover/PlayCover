//
//  KeyboardController.swift
//  PlayCoverInject
//

import Foundation
import GameController


extension GCKeyboard {
    static func pressed(key : GCKeyCode) -> Bool{
        return GCKeyboard.coalesced?.keyboardInput?.button(forKeyCode: key)?.isPressed ?? false
    }
}

class KeyboardController {
    
    static let shared = KeyboardController()
    
    var active = true
    
    var controls = [Action]()
    
    func setup(){
        controls = []
        if let keys = OverlayController.shared.realTimeControls ?? UserDefaults.standard.array(forKey: "playcover.layout"){
            if(!keys.isEmpty){
                var counter = 3
                for case let key as Array<CGFloat> in keys{
                    
                    if(key.count == 4){
                        controls.append(ButtonAction(id: counter, key: GCKeyCode.init(rawValue: CFIndex(key[0])), point: CGPoint(x: key[1], y: key[2])))
                    } else if(key.count == 8){
                        controls.append(JoystickAction(id: counter, keys:  [GCKeyCode.init(rawValue: CFIndex(key[0])), GCKeyCode.init(rawValue: CFIndex(key[1])), GCKeyCode.init(rawValue: CFIndex(key[2])), GCKeyCode.init(rawValue: CFIndex(key[3]))], center: CGPoint(x: key[4],y: key[5]), shift: key[6]))
                    }
                    counter+=1
                }
            }
        }
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            keyboard.button(forKeyCode: .leftAlt)?.pressedChangedHandler = { (key, keyCode, pressed) in
                if(pressed){
                    MouseEmitter.shared.setActive(active:  true)
                } else{
                    MouseEmitter.shared.setActive(active:  false)
                }
            }
        }
    }
    
}

protocol Action{
    
}

class ButtonAction : Action {
    
    let key : GCKeyCode
    let point : CGPoint
    var id : Int
    
    init(id: Int, key : GCKeyCode, point : CGPoint){
        self.key = key
        self.point = point
        self.id = id
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            keyboard.button(forKeyCode: key)?.pressedChangedHandler = { (key, keyCode, pressed) in
                if pressed {
                    self.update(pressed: pressed)
                } else {
                    self.update(pressed: pressed)
                }
            }
        }
    }
    
    func update(pressed : Bool){
        if(pressed){
            Toucher.touch(point: point, phase: UITouch.Phase.began, tid: id)
        } else {
            Toucher.touch(point: point, phase: UITouch.Phase.ended, tid: id)
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
        self.shift = shift
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
    
    func update(){
        var touch = center
        if(GCKeyboard.pressed(key: keys[0])){
            touch.y = touch.y - shift
        } else if(GCKeyboard.pressed(key: keys[1])){
            touch.y = touch.y + shift
        }
        if(GCKeyboard.pressed(key: keys[2])){
            touch.x = touch.x - shift
        } else if(GCKeyboard.pressed(key: keys[3])){
            touch.x = touch.x + shift
        }
        if(moving){
            if(touch.equalTo(center)){
                moving = false
                Toucher.touch(point: center, phase: UITouch.Phase.ended, tid: id)
            } else{
                Toucher.touch(point: touch, phase: UITouch.Phase.moved, tid: id)
            }
        } else{
            moving = true
            Toucher.touch(point: touch, phase: UITouch.Phase.began, tid: id)
        }
    }
}
