//
//  NSWindowHelper.swift
//  MacHelper
//
//  Created by Alice on 23.06.2021.
//

import Foundation
import AppKit

@objc public class NSWindowHelper : NSObject {
    
    @objc static public func initUI(){
        let window = NSApplication.shared.windows.first
        var frame = window?.frame
        if let screen = NSScreen.main {
            let rect = screen.frame
            let height = rect.size.height
            let width = rect.size.width
            frame?.size = NSSize(width: width / 2, height: height / 2)
        }
        
        window?.setFrame(frame!, display: true)
        window?.center()
    }
}
