//
//  PlayViews.swift
//  PlayTools
//

import Foundation

let ui = PlayUI.shared

final class PlayUI {
    
    static let shared = PlayUI()
    
    private init() {}
    
    func showAlert(_ title : String, _ content : String) {
        let ac = UIAlertController(title: title, message: content, preferredStyle: .alert)
        input.root?.present(ac, animated: true, completion: nil)
    }
    
    func showLauncherWarning() -> Void {
        let ac = UIAlertController(title: "PlayCover Launcher is not found!", message: "Please, install it from playcover.me site to use this app.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default){ _ in
            Dynamic.NSApplication.sharedApplication.terminate(self)
        })
        input.root?.present(ac, animated: true, completion: nil)
    }
    
}
