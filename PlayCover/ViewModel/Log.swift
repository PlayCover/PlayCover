//
//  Logger.swift
//  PlayCover
//

import Foundation
import SwiftUI

class Log: ObservableObject {

    static let shared = Log()

    func error(_ err: Error) {
        DispatchQueue.main.async {
            self.dialog(
                question: NSLocalizedString("alert.error", comment: ""),
                text: err.localizedDescription,
                style: NSAlert.Style.critical)
        }
    }

    func msg(_ msg: String) {
        DispatchQueue.main.async {
            self.log(msg)
            self.dialog(
                question: NSLocalizedString("alert.success", comment: ""),
                text: msg,
                style: NSAlert.Style.informational)
        }
    }

    var logdata = "\(ProcessInfo.processInfo.operatingSystemVersionString)\n"

    func log(_ str: String, isError: Bool = false) {
        print(str)
        if isError {
            logdata.append("ERROR: ")
        }
        logdata.append(str)
        logdata.append("\n")
    }

    private func dialog(question: String, text: String, style: NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = style
        alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
        alert.runModal()
    }

    required init() { }
}
