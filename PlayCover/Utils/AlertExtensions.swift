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
        alert.messageText = NSLocalizedString("alert.differentBundleIdKeymap.message", comment: "")
        alert.informativeText = NSLocalizedString("alert.differentBundleIdKeymap.text", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("button.Proceed", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))

        let result = alert.runModal()
        response(result)
    }
}
