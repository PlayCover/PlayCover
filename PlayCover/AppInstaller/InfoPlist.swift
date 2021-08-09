//
//  Extensions.swift
//  PlayCover
//

import Foundation

class InfoPlist {
    
    private var infoPlistUrl : URL? = nil
    private var dict : NSDictionary? = nil
    
    func appName() throws -> String {
        return try plistValue(key: "CFBundleExecutable")
    }
    
    func bundleName() throws -> String {
        return try plistValue(key: "CFBundleDisplayName")
    }
    
    func plistValue(key : String) throws -> String {
        if let value = dict?[key] as? String{
            return value
        }
        throw PlayCoverError.infoPlistNotFound
    }
    
    static func readInfoPlist(app: URL) throws -> InfoPlist {
        let list = app.appendingPathComponent("Info.plist", isDirectory: false)
        if fm.fileExists(atPath: list.path){
            if let dict = NSDictionary(contentsOfFile: list.path){
                let info = InfoPlist()
                info.infoPlistUrl = list
                info.dict = dict
                return info
            }
        }
        throw PlayCoverError.infoPlistNotFound
    }
    
    func patchMinVersion() throws {
        ulog("Patching Minimum OS version\n")
        if let info = infoPlistUrl {
            let newDict = dict?.mutableCopy() as! NSMutableDictionary
            if Double(newDict["MinimumOSVersion"] as! String)! > 11.0 {
                newDict["MinimumOSVersion"] = 11
            }
            newDict.write(toFile: info.path, atomically: true)
            return
        }
        throw PlayCoverError.infoPlistNotFound
    }
}
