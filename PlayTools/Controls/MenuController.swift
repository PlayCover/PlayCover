/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Menu construction extensions for this sample.
 */

import UIKit

extension UIViewController {
    
    @objc
    func switchEditorMode(_ sender: AnyObject) {
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
    func startTouchRecording(_ sender: AnyObject) {
        
    }
    
    @objc
    func stopTouchRecording(_ sender: AnyObject) {
        
    }
    
    @objc
    func loopTouchRecording(_ sender: AnyObject) {
        
    }
    
}
struct CommandsList {
    static let KeymappingToolbox = "keymapping"
    static let MacrosToolbox = "macros"
}

var keymapping = ["Open/Close Keymapping Editor", "Delete selected element", "Upsize selected element", "Downsize selected element"]
var keymappingSelectors = [#selector(UIViewController.switchEditorMode(_:)), #selector(UIViewController.removeElement(_:)), #selector(UIViewController.upscaleElement(_:)), #selector(UIViewController.downscaleElement(_:))]

var macros = ["Start touch recording", "Stop recording", "Loop current recording"] // "Replay current recording",
var macroSelectors = [#selector(UIViewController.startTouchRecording(_:)), #selector(UIViewController.stopTouchRecording(_:)), #selector(UIViewController.loopTouchRecording(_:))]

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
                         action: keymappingSelectors[keymapping.index(of: btn)!],
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
        let keyCommands = [ "O","P","L" ]
        
        let macroCommands = zip(keyCommands, macros).map { (command, btn) in
            UIKeyCommand(title: btn,
                         image: nil,
                         action: keymappingSelectors[macros.firstIndex(of: btn)!],
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
    static var keymappingMenu: UIMenu.Identifier { UIMenu.Identifier("me.playcover.PlayTools.menus.editor") }
    static var keymappingOptionsMenu: UIMenu.Identifier { UIMenu.Identifier("me.playcover.PlayTools.menus.keymapping") }
    static var macrosMenu: UIMenu.Identifier { UIMenu.Identifier("me.playcover.PlayTools.menus.macros") }
    static var macrosActionsMenu: UIMenu.Identifier { UIMenu.Identifier("me.playcover.PlayTools.menus.touchrecord") }
}
