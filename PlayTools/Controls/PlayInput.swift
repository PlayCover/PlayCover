import Foundation
import GameController
import UIKit

final class PlayInput: NSObject {
    
    static let shared = PlayInput()
    
    var actions = [Action]()
    
    var timeoutForBind = true
    
    func invalidate(){
        MacroController.shared.stopReplaying()
        PlayMice.shared.stop()
        for c in self.actions{
            c.invalidate()
        }
    }
    
    func setup(){
        actions = []
        var counter = 2
        for key in settings.layout {
            if(key.count == 4){
                actions.append(ButtonAction(id: counter, keyid: Int(key[0]), key: GCKeyCode.init(rawValue: CFIndex(key[0])), point: CGPoint(x: key[1].absoluteX, y: key[2].absoluteY)))
            } else if(key.count == 8){
                actions.append(JoystickAction(id: counter, keys:  [GCKeyCode.init(rawValue: CFIndex(key[0])), GCKeyCode.init(rawValue: CFIndex(key[1])), GCKeyCode.init(rawValue: CFIndex(key[2])), GCKeyCode.init(rawValue: CFIndex(key[3]))], center: CGPoint(x: key[4].absoluteX,y: key[5].absoluteY), shift: key[6].absoluteSize))
            } else if key.count == 2 && PlaySettings.shared.gamingMode {
                PlayMice.shared.setup(key)
            }
            counter += 1
        }
        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            keyboard.keyChangedHandler = { (input, _, keyCode, pressed) in
                if EditorController.shared.isReadyToBeOpened && !mode.visible && !editor.editorMode && keyCode == GCKeyCode.keyK && ( keyboard.button(forKeyCode: GCKeyCode(rawValue: 227))!.isPressed || keyboard.button(forKeyCode: GCKeyCode(rawValue: 231))!.isPressed ){
                    mode.show(true)
                    EditorController.shared.switchMode()
                } else if editor.editorMode && !PlayInput.FORBIDDEN.contains(keyCode) && self.isSafeToBind(keyboard){
                    EditorController.shared.setKeyCode(keyCode.rawValue)
                }
                
            }
            keyboard.button(forKeyCode: .leftAlt)?.pressedChangedHandler = { (key, keyCode, pressed) in
                self.swapMode(pressed)
            }
            keyboard.button(forKeyCode: .rightAlt)?.pressedChangedHandler = { (key, keyCode, pressed) in
                self.swapMode(pressed)
            }
        }
    }
    
    private func isSafeToBind(_ input : GCKeyboardInput) -> Bool {
           var result = true
           for f in PlayInput.FORBIDDEN {
               if input.button(forKeyCode: f)?.isPressed ?? false {
                   result = false
                   break
               }
           }
           return result
       }
    
    private static let FORBIDDEN : [GCKeyCode] = [
        GCKeyCode.init(rawValue: 227),
        GCKeyCode.init(rawValue: 231),
        .leftAlt,
        .rightAlt,
        .escape,
        .printScreen,
        .F1,
        .F2,
        .F3,
        .F4,
        .F5
    ]
    
    private func swapMode(_ pressed : Bool){
        if !PlaySettings.shared.gamingMode {
            return
        }
        if pressed {
            if !mode.visible{
                self.invalidate()
            }
            mode.show(!mode.visible)
        }
    }
    
    var root : UIViewController? {
        return screen.window?.rootViewController
    }
    
    
    func initialize() {
        
        if PlaySettings.shared.keymapping == false {
            return
        }
        
        let centre = NotificationCenter.default
        let main = OperationQueue.main
        
        centre.addObserver(forName: NSNotification.Name.GCKeyboardDidConnect, object: nil, queue: main) { (note) in
            PlayInput.shared.setup()
        }
        
        centre.addObserver(forName: NSNotification.Name.GCMouseDidConnect, object: nil, queue: main) { (note) in
            PlayInput.shared.setup()
        }
        
        setup()
        fixBeepSound()
    }
    
    private func fixBeepSound() {
        Dynamic.NSEvent.addLocalMonitorForEventsMatchingMask(1024, handler: { event in
            if !mode.visible {
                return nil
            }
            return event
        } as ResponseBlock)
    }
    
}



