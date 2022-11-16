//
//  AlertExtensions.swift
//  PlayCover
//
//  Created by Nick on 2022-11-16.
//

import AppKit

extension NSAlert {
    static func differentBundleIdKeymap(response: (NSApplication.ModalResponse) -> Void) {
        let alert = NSAlert()
        alert.messageText = "The name of the keymap is different from the bundle ID of the app!"
        alert.informativeText = "The keymap may have been created for another application."
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("button.Proceed", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))
        
        let result = alert.runModal()
        response(result)
    }
}
