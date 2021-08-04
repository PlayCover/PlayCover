//
//  AppCreator.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation
import Zip

struct AppModel: Identifiable {
    
    var id: URL
    let name : String
    let downloaded : Bool
    let icon : URL
    
    init(name : String, path: URL, icon : URL, downloaded : Bool = false) {
        self.name = name
        self.icon = icon
        self.downloaded = downloaded
        self.id = path
    }
}

struct Return {
    let app : AppModel?
    let log : String
    let success : Bool
    init(app : AppModel?, log : String, success : Bool) {
        self.app = app
        self.log = log
        self.success = success
    }
}

class AppCreator {
    
    enum PlayCoverError: Error {
        case runtimeError(String)
    }
    
    static let possibleHeaders : [Array<UInt8>] = [
        [202,254,186, 190],
        [207 ,250 ,237 ,254],
    ]
    
    
    static func convertApp(url : URL){
        var files = [URL]()
        let fm = FileManager.default
        if let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        if var bts = bytesFromFile(filePath: fileURL.path)?[...3]{
                            var exec = fm.isExecutableFile(atPath: fileURL.path)
                            if bts.count == 4{
                                if(possibleHeaders.contains(Array(bts)) || fileURL.pathExtension.contains("dylib") || exec){
                                    
                                    let newURL = URL(fileURLWithPath: fileURL.path.appending("_sim"))
                                    try fm.copyItem(at: fileURL, to: newURL)
                                    
                                    if convert(fileURL.path) == -24{
                                        throw PlayCoverError.runtimeError("Currently implementation of this method is not exposed")
                                    }
                                    
                                    var ext = fileURL.pathExtension
                                    try fm.removeItem(at: fileURL)
                                    try fm.moveItem(at: newURL, to: fileURL)
                                    if exec{
                                        var attributes = [FileAttributeKey : Any]()
                                        attributes[.posixPermissions] = 0o755
                                        try fm.setAttributes(attributes, ofItemAtPath: fileURL.path)
                                    }
                                    print(shell("vtool -arch arm64 -set-build-version maccatalyst 10.0 14.5 -replace -output \(fileURL.path) \(fileURL.path)"))
                                    print(shell("codesign -fs- \(fileURL.path.escape())"))
                                }
                            }
                            
                        }
                    }
                } catch {
                    print(error, fileURL)
                }
            }
        }
    }
    
    static func extractAppFromIPA(url : URL) -> (URL?, String, Bool, URL){
        var localLog = ""
        var newZipurl = getDocs().appendingPathComponent(url.lastPathComponent)
        let newURL = newZipurl.deletingPathExtension().appendingPathExtension("zip")
        var deleteDir = getDocs().appendingPathComponent(newURL.deletingPathExtension().lastPathComponent)
        
        localLog.append(shell("xattr -rd com.apple.quarantine \(url.path)"))
        
        do {
            
            let fm = FileManager.default
            
            try fm.copyItem(at: url, to: newZipurl)
            
            try fm.moveItem(at: url, to: newURL)
            
            try Zip.quickUnzipFile(newURL)
            
            let targetPath = getDocs().appendingPathComponent(newURL.deletingPathExtension().lastPathComponent).appendingPathComponent("Payload", isDirectory: true)
            let targetUrl = try targetPath.subDirectories()[0]
            try fm.removeItem(at: newZipurl)
            return (targetUrl, localLog, true, deleteDir)
        } catch {
            localLog.append("IPA file is corrupted. No .app directory found.")
            return (URL(fileURLWithPath: ""), localLog, false, deleteDir)
        }
        
    }
    
    static func copyApp(url : URL, returnCompletion: @escaping (Return) -> ()){
        DispatchQueue.global(qos: .background).async {
            let fm = FileManager.default
            var outputLog = ""
            let newPath = getDocs()
            var success = false
            var targetURL : URL? = url
            var deleteDir : URL
            (targetURL,outputLog, success, deleteDir) = extractAppFromIPA(url: url)
            
            if !success{
                returnCompletion(Return(app: nil, log: outputLog, success: false))
            }
            
            if let innerUrl = targetURL{
                
                if !fm.fileExists(atPath: newPath.appendingPathComponent(innerUrl.lastPathComponent).path) {
                    do {
                        
                        try fm.moveItem(at: innerUrl, to: newPath.appendingPathComponent(innerUrl.lastPathComponent))
                        try fm.removeItem(at: innerUrl.deletingLastPathComponent().deletingLastPathComponent())
                        
                        let appPath = newPath.appendingPathComponent(innerUrl.lastPathComponent).path
                        
                        try fm.removeItem(at: deleteDir.appendingPathExtension("zip"))
                        
                        outputLog.append("Removing app from quarantine\n")
                        outputLog.append(shell("xattr -rd com.apple.quarantine \(appPath)"))
                        outputLog.append("Converting app\n")
                        convertApp(url: newPath.appendingPathComponent(innerUrl.lastPathComponent))
                        
                        outputLog.append("Fixing executable\n")
                        let plistUrl = newPath.appendingPathComponent(innerUrl.lastPathComponent).appendingPathComponent("Info.plist")
                        var iconUrl = newPath.appendingPathComponent(innerUrl.lastPathComponent).appendingPathComponent("AppIcon60x60@2x.png")
                        if let iconName = getIconNameFromPlist(url: plistUrl){
                            iconUrl = newPath.appendingPathComponent(innerUrl.lastPathComponent).appendingPathComponent(iconName)
                        }
                        if let execName = getExecutableNameFromPlist(url: plistUrl){
                            let execpath = newPath.appendingPathComponent(url.lastPathComponent).appendingPathComponent(execName).path
                            outputLog.append(shell("chmod 755 \(execpath)"))
                        }
                        
                        outputLog.append("Codesigning\n")
                        let ents = createEntitlements()
                        outputLog.append(shell("codesign -fs- \(newPath.appendingPathComponent(innerUrl.lastPathComponent).path) --deep --entitlements \(ents.path)"))
                        
                        try fm.removeItem(at: ents)
                        
                        returnCompletion(Return(app: AppModel(name: innerUrl.lastPathComponent, path: newPath.appendingPathComponent(innerUrl.lastPathComponent), icon: iconUrl, downloaded: true), log: outputLog, success: true))
                        
                    } catch {
                        print(error.localizedDescription)
                        outputLog.append(error.localizedDescription)
                        returnCompletion(Return(app: nil, log: outputLog, success: false))
                    }
                }
                
            }
            
        }
    }
    
    static func createEntitlements() -> URL{
        let str = """
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
        let filename = getDocs().appendingPathComponent("ent.plist")
        
        do {
            try str.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch {
        }
        return filename
    }
    
}
