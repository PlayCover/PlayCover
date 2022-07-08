//
//  PlayCover.swift
//  PlayTools
//

import Foundation
import UIKit
import Security
import MetalKit
import WebKit

final public class PlayCover : NSObject {
    
    @objc static let shared = PlayCover()
    
    var menuController: MenuController?
    
    var firstTime = true
    
    private override init() {}
    
    @objc static public func launch(){
        PlaySettings.shared.setupLayout()
        PlayInput.shared.initialize()
        PlaySettings.shared.clearLegacy()
    }
    
    @objc static public func initMenu( menu : NSObject){
        delay(0.005){
            shared.menuController = MenuController(with: menu as! UIMenuBuilder)
            delay(0.005){
                UIMenuSystem.main.setNeedsRebuild()
                UIMenuSystem.main.setNeedsRevalidate()
            }
        }
    }
    
    static func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
    
    func processSubviews(of view: UIView?) {
        if let v = view{
            for subview in v.subviews {
                print(subview.description)
                processSubviews(of: subview)
            }
        }
    }
    
}

@objc extension FileManager {
    
    private static let FOUNDATION = "/System/Library/Frameworks/Foundation.framework/Foundation"
    
    static func classInit()  {
        let originalMethod = class_getInstanceMethod(FileManager.self, #selector(fileExists(atPath:)))
        let swizzledMethod = class_getInstanceMethod(FileManager.self, #selector(hook_fileExists(atPath:)))
        method_exchangeImplementations(originalMethod!, swizzledMethod!)
        
        let originalMethod2 = class_getInstanceMethod(FileManager.self, #selector(fileExists(atPath:isDirectory:)))
        let swizzledMethod2 = class_getInstanceMethod(FileManager.self, #selector(hook_fileExists(atPath:isDirectory:)))
        
        let originalMethod3 = class_getInstanceMethod(FileManager.self, #selector(isReadableFile(atPath:)))
        let swizzledMethod3 = class_getInstanceMethod(FileManager.self, #selector(hook_isReadableFile(atPath:)))
        
        method_exchangeImplementations(originalMethod3!, swizzledMethod3!)
    }
    
    @objc func hook_fileExists(atPath: String) -> Bool {
        let answer = hook_fileExists(atPath: atPath)
        if atPath.elementsEqual(FileManager.FOUNDATION){
            return true
        }
        return answer
    }
    
    @objc func hook_fileExists(atPath path: String,
                               isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        let answer = hook_fileExists(atPath: path, isDirectory: isDirectory)
        if path.elementsEqual(FileManager.FOUNDATION){
            return true
        }
        return answer
    }
    
    @objc func hook_isReadableFile(atPath path: String) -> Bool {
        let answer = hook_isReadableFile(atPath: path)
        if path.elementsEqual(FileManager.FOUNDATION){
            return true
        }
        return answer
    }
    
}



