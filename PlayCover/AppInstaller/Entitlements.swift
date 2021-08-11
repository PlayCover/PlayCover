//
//  Entitlements.swift
//  PlayCover
//

import Foundation

class Entitlements {
    
    static func createEntitlements(temp: URL, exec : URL) throws -> URL{
        ulog("Creating entitlements file\n")
        let ents = temp.appendingPathComponent("ent.plist")
        if vm.fixLogin{
            try copyEntitlements(exec: exec).write(to: ents, atomically: true, encoding: String.Encoding.utf8)
            try addSandobox(ents: ents)
        } else{
            try Entitlements.entitlements_template.write(to: ents, atomically: true, encoding: String.Encoding.utf8)
        }
        return ents
    }
    
    static func copyEntitlements(exec: URL) throws -> String {
        ulog("Copying entitlements \n")
        var en = excludeEntitlements(exec: exec)
        if !en.contains("DOCTYPE plist PUBLIC"){
            en = Entitlements.entitlements_template
        }
        return en
    }
    
    static func excludeEntitlements(exec : URL) -> String {
        let from = sh.fetchEntitlements(exec)
        if let range: Range<String.Index> = from.range(of: "<?xml") {
            return String(from[range.lowerBound...])
        }
        else {
            return Entitlements.entitlements_template
        }
    }
    
    static func addSandobox(ents : URL) throws {
        ulog("Adding Sandbox\n")
        if let plist = NSDictionary(contentsOfFile: ents.path){
            if let dict = (plist as NSDictionary).mutableCopy() as? NSMutableDictionary{
                dict["com.apple.security.app-sandbox"] = true
                dict["com.apple.security.network.client"] = true
                dict["com.apple.security.network.server"] = true
                dict.write(toFile: ents.path, atomically: true)
            } else{
                throw PlayCoverError.ipaCorrupted
            }
        } else{
            throw PlayCoverError.ipaCorrupted
        }
        
    }
  
    static let entitlements_template = """
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>com.apple.security.app-sandbox</key>
        <true/>
        <key>com.apple.security.network.client</key>
        <true/>
        <key>com.apple.security.network.server</key>
        <true/>
    </dict>
    </plist>
    """

}
