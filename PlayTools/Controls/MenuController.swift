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
    
}
struct CommandPListKeys {
        static let ArrowsKeyIdentifier = "id" // Arrow command-keys
        static let CitiesKeyIdentifier = "city" // City command-keys
        static let TownsIdentifierKey = "town" // Town commands
        static let StylesIdentifierKey = "font" // Font style commands
        static let ToolsIdentifierKey = "tool" // Tool commands
    }

var arrowss = ["Open/Close Keymapping Editor", "Delete selected element", "Upsize selected element", "Downsize selected element"]
var selectors = [#selector(UIViewController.switchEditorMode(_:)), #selector(UIViewController.removeElement(_:)), #selector(UIViewController.upscaleElement(_:)), #selector(UIViewController.downscaleElement(_:))]

class MenuController {
    
    init(with builder: UIMenuBuilder) {
        if #available(iOS 15.0, *) {
            builder.insertSibling(MenuController.navigationMenu(), afterMenu: .view)
        } else {
            
        }
    }
   
    @available(iOS 15.0, *)
    class func navigationMenu() -> UIMenu {
        let keyCommands = [ "K", UIKeyCommand.inputDelete , UIKeyCommand.inputUpArrow, UIKeyCommand.inputDownArrow ]
            
            let arrowKeyChildrenCommands = zip(keyCommands, arrowss).map { (command, arrow) in
                UIKeyCommand(title: arrow,
                             image: nil,
                             action: selectors[arrowss.index(of: arrow)!],
                             input: command,
                             modifierFlags: .command,
                             propertyList: [CommandPListKeys.ArrowsKeyIdentifier: arrow]
                          )
            }
            
            let arrowKeysGroup = UIMenu(title: "",
                          image: nil,
                          identifier: .arrowsMenu,
                          options: .displayInline,
                          children: arrowKeyChildrenCommands)
            
            return UIMenu(title: NSLocalizedString("Keymapping", comment: ""),
                          image: nil,
                          identifier: .navMenu,
                          options: [],
                          children: [arrowKeysGroup])
        }
    
}

extension UIMenu.Identifier {
    static var navMenu: UIMenu.Identifier { UIMenu.Identifier("me.playcover.PlayTools.menus.editor") }
    static var arrowsMenu: UIMenu.Identifier { UIMenu.Identifier("me.playcover.PlayTools.menus.keymapping") }
}
