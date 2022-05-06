//
//  Logger.swift
//  PlayCover
//

import Foundation
import SwiftUI

class Log: ObservableObject {
    
    static let shared = Log()
    
    func error(_ e : Error){
        DispatchQueue.main.async {
            self.dialog(question: "Some error happened!", text: e.localizedDescription, style: NSAlert.Style.critical)
        }
    }
    
    func msg(_ msg : String){
        DispatchQueue.main.async {
            self.log(msg)
            self.dialog(question: "Success!", text: msg, style: NSAlert.Style.informational)
        }
    }
    
    var logdata : String = "\(ProcessInfo.processInfo.operatingSystemVersionString)\n"
    
    func log(_ s : String, isError : Bool = false) {
        print(s)
        if isError{
            logdata.append("ERROR: ")
        }
        logdata.append(s)
        logdata.append("\n")
    }
    
    private func dialog(question: String, text: String, style : NSAlert.Style) {
        let alert = NSAlert()
        alert.messageText = question
        alert.informativeText = text
        alert.alertStyle = style
        alert.addButton(withTitle: "OK")
        return alert.beginSheetModal(for: NSApp.mainWindow!) {_ in
        }
    }
    
    required init() {}
}
