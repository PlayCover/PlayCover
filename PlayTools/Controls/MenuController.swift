/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Menu construction extensions for this sample.
 */

import UIKit

extension UIViewController {
    
    
    
    @objc
    func switchEditorMode(_ sender: AnyObject) {
        MacroController.shared.stopReplaying()
        EditorController.shared.switchMode()
    }
    
    @objc
    func removeElement(_ sender: AnyObject) {
        EditorController.shared.removeControl()
    }
    
    @objc
    func upscaleElement(_ sender: AnyObject) {
        EditorController.shared.focusedControl?.resize(down: false)
    }
    
    @objc
    func downscaleElement(_ sender: AnyObject) {
        EditorController.shared.focusedControl?.resize(down: true)
    }
    
    // Macros
    @objc
    func switchTouchRecording(_ sender: AnyObject) {
        if MacroController.shared.isRecording {
            MacroController.shared.stopRecording()
        } else{
            MacroController.shared.startRecording()
        }
    }
    
    @objc
    func switchTouchReplaying(_ sender: AnyObject) {
        if MacroController.shared.isReplaying {
            MacroController.shared.stopReplaying()
        } else{
            MacroController.shared.startReplaying()
        }
    }
    
    @objc
    func switchTouchReplayingLoop(_ sender: AnyObject) {
        if MacroController.shared.isReplaying {
            MacroController.shared.stopReplaying()
        } else{
            MacroController.shared.startReplayingLoop()
        }
    }
    
}

struct CommandsList {
    static let KeymappingToolbox = "keymapping"
    static let MacrosToolbox = "macros"
}

var keymapping = ["Open/Close Keymapping Editor", "Delete selected element", "Upsize selected element", "Downsize selected element"]
var keymappingSelectors = [#selector(UIViewController.switchEditorMode(_:)), #selector(UIViewController.removeElement(_:)), #selector(UIViewController.upscaleElement(_:)), #selector(UIViewController.downscaleElement(_:))]

var macros = ["Start/Stop touch recording", "Start/Stop replaying", "Loop/Stop replaying"]
var macroSelectors = [#selector(UIViewController.switchTouchRecording(_:)), #selector(UIViewController.switchTouchReplaying(_:)), #selector(UIViewController.switchTouchReplayingLoop(_:))]

class MenuController {
    
    init(with builder: UIMenuBuilder) {
        if #available(iOS 15.0, *) {
            builder.insertSibling(MenuController.keymappingMenu(), afterMenu: .view)
            builder.insertSibling(MenuController.macrosMenu(), afterMenu: .keymappingMenu)
        } else {
            
        }
    }
    
    @available(iOS 15.0, *)
    class func keymappingMenu() -> UIMenu {
        let keyCommands = [ "K", UIKeyCommand.inputDelete , UIKeyCommand.inputUpArrow, UIKeyCommand.inputDownArrow ]
        
        let arrowKeyChildrenCommands = zip(keyCommands, keymapping).map { (command, btn) in
            UIKeyCommand(title: btn,
                         image: nil,
                         action: keymappingSelectors[keymapping.firstIndex(of: btn)!],
                         input: command,
                         modifierFlags: .command,
                         propertyList: [CommandsList.KeymappingToolbox: btn]
            )
        }
        
        let arrowKeysGroup = UIMenu(title: "",
                                    image: nil,
                                    identifier: .keymappingOptionsMenu,
                                    options: .displayInline,
                                    children: arrowKeyChildrenCommands)
        
        return UIMenu(title: NSLocalizedString("Keymapping", comment: ""),
                      image: nil,
                      identifier: .keymappingMenu,
                      options: [],
                      children: [arrowKeysGroup])
    }
    
    @available(iOS 15.0, *)
    class func macrosMenu() -> UIMenu {
        let keyCommands = ["O","P","L" ]
        
        let macroCommands = zip(keyCommands, macros).map { (command, btn) in
            UIKeyCommand(title: btn,
                         image: nil,
                         action: macroSelectors[macros.firstIndex(of: btn)!],
                         input: command,
                         modifierFlags: .command,
                         propertyList: [CommandsList.MacrosToolbox: btn]
            )
        }
        
        let macrosKeysGroup = UIMenu(title: "",
                                    image: nil,
                                         identifier: .macrosMenu,
                                    options: .displayInline,
                                    children: macroCommands)
        
        return UIMenu(title: NSLocalizedString("Macros", comment: ""),
                      image: nil,
                      identifier: .macrosActionsMenu,
                      options: [],
                      children: [macrosKeysGroup])
    }
    
    
}


extension UIMenu.Identifier {
    static var keymappingMenu: UIMenu.Identifier { UIMenu.Identifier("io.playcover.PlayTools.menus.editor") }
    static var keymappingOptionsMenu: UIMenu.Identifier { UIMenu.Identifier("io.playcover.PlayTools.menus.keymapping") }
    static var macrosMenu: UIMenu.Identifier { UIMenu.Identifier("io.playcover.PlayTools.menus.macros") }
    static var macrosActionsMenu: UIMenu.Identifier { UIMenu.Identifier("io.playcover.PlayTools.menus.touchrecord") }
}
