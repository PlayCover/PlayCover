//
//  ScreenController.swift
//  PlayTools
//

import Foundation
import UIKit
import SwiftUI
import AVFoundation

let screen = PlayScreen.shared

extension CGSize {
    func aspectRatio() -> CGFloat{
        if width > height{
            return width / height
        } else{
            return height / width
        }
    }
    
    func toAspectRatio() -> CGSize {
        return CGSize(width: height / UIScreen.aspectRatio, height: height)
    }
}

extension CGRect {
    
    func aspectRatio() -> CGFloat{
        if width > height{
            return width / height
        } else{
            return height / width
        }
    }
    
    func toAspectRatio() -> CGRect {
        return CGRect(x: minX, y : minY, width: height / UIScreen.aspectRatio, height: height)
    }
    
    func toAspectRatioReversed() -> CGRect {
        return CGRect(x: minX, y : minY, width: width, height: width / UIScreen.aspectRatio)
    }
   
}

extension UIScreen {
    
    static var aspectRatio : CGFloat {
        let count = Dynamic.NSScreen.screens.count.asInt ?? 0
        if PlaySettings.shared.notch  {
            if count == 1 {
                return 1.6
            } else {
                if Dynamic.NSScreen.mainScreen.asObject == Dynamic.NSScreen.screens.first {
                    return 1.6
                }
            }
           
        }
        if let frame = Dynamic(Dynamic.NSScreen.mainScreen.asObject).frame.asCGRect {
            return frame.aspectRatio()
        }
        return 1.6
    }
}

public final class PlayScreen : NSObject {
    
    @objc public static let shared = PlayScreen()
    
    @objc public static func frame(_ rect : CGRect) -> CGRect {
        return rect.toAspectRatio()
    }
    
    @objc public static func bounds(_ rect : CGRect) -> CGRect {
        return rect.toAspectRatioReversed()
    }
    
    @objc public static func width(_ size : Int) -> Int {
        return size;
    }
    
    @objc public static func height(_ size : Int) -> Int {
        return Int(size / Int(UIScreen.aspectRatio))
    }
    
    @objc public static func sizeAspectRatio(_ size : CGSize) -> CGSize {
        return size.toAspectRatio()
    }
    
    var fullscreen : Bool {
        return Dynamic(nsWindow).styleMask.contains(16384).asBool ?? false
    }
    
    @objc public var screenRect : CGRect {
        return UIScreen.main.bounds
    }
    
    var width : CGFloat {
        screenRect.width
    }
    
    var height : CGFloat {
        screenRect.height
    }
    
    var max : CGFloat {
        Swift.max(width, height)
    }
    
    var percent : CGFloat {
        max / 100.0
    }
    
    var window : UIWindow? {
        return UIApplication.shared.windows.first
    }
    
    var nsWindow : NSObject? {
        window?.nsWindow
    }
    
    var nsScreen : NSObject? {
        Dynamic(nsWindow).nsScreen.asObject
    }
    
    func switchDock(_ visible : Bool) {
        Dynamic.NSMenu.setMenuBarVisible(visible)
    }
    
}

extension CGFloat {
    var relativeY : CGFloat {
        self / screen.height
    }
    var relativeX : CGFloat {
        self / screen.width
    }
    var relativeSize : CGFloat {
        self / screen.percent
    }
    var absoluteSize : CGFloat {
        self * screen.percent
    }
    var absoluteX : CGFloat {
        self * screen.width
    }
    var absoluteY : CGFloat {
        self * screen.height
    }
}

extension UIView {

    class func allSubviews<T: UIView>(from parenView: UIView) -> [T] {
        return parenView.subviews.flatMap { subView -> [T] in
            var result = allSubviews(from: subView) as [T]
            if let view = subView as? T { result.append(view) }
            return result
        }
    }
}

extension UIScreen {
    
    @objc open var maximumFramesPerSecond: Int {
        return PlaySettings.shared.refreshRate
    }
    
    @available(iOS 15.0, *)
     @objc open var preferredFrameRateRange: CAFrameRateRange {
         return CAFrameRateRange(minimum: 60, maximum: Float(PlaySettings.shared.refreshRate), __preferred: Float(PlaySettings.shared.refreshRate))
     }
    
}

@objc extension CADisplayLink {
    @objc open var preferredFramesPerSecond: Int {
        return PlaySettings.shared.refreshRate
    }
}

extension UIWindow {
    
    var nsWindow: NSObject? {
        guard let nsWindows = NSClassFromString("NSApplication")?.value(forKeyPath: "sharedApplication.windows") as? [AnyObject] else { return nil }
        for nsWindow in nsWindows {
            let uiWindows = nsWindow.value(forKeyPath: "uiWindows") as? [UIWindow] ?? []
            if uiWindows.contains(self) {
                return nsWindow as? NSObject
            }
        }
        return nil
    }
}

extension NSObject {
    func call(_ method : String, object : CGSize) -> Bool{
        if self.responds(to: Selector(method)) {
            self.perform(Selector(method), with: object)
            return true
        } else {
            return false
        }
    }
    func call(_ method : String) -> Bool{
        if self.responds(to: Selector(method)) {
            self.perform(Selector(method))
            return true
        } else {
            return false
        }
    }
}
