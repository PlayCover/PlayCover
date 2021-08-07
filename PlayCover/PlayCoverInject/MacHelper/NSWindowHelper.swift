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
        var window = NSApplication.shared.windows.first
        var frame = window?.frame
        //frame?.size = NSSize(width: 1107, height:735)
        frame?.size = NSSize(width: 1440, height:900)
        //window?.toggleFullScreen(nil)
        window?.setFrame(frame!, display: true)
        window?.center()
    }
}
