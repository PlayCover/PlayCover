//
//  AppCreator.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation

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
        [202,254,186,190],
        [207 ,250 ,237 ,254],
    ]
  
    
    static func convertApp(url : URL){
        var files = [URL]()
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        var oldPath = fileURL.path.replacingOccurrences(of: " ", with: "\\ ")
                        if var bts = bytesFromFile(filePath: fileURL.path)?[...3]{
                            var exec = FileManager.default.isExecutableFile(atPath: oldPath)
                            if bts.count == 4{
                                if(possibleHeaders.contains(Array(bts)) || fileURL.pathExtension.contains("dylib") || exec){
                                    print(fileURL)
                                    
                                    shell("cp \(oldPath) \(oldPath)_sim")
                                    var newPath = oldPath.appending("_sim")
                                    
                                    
                                    if convert(fileURL.path) == -24{
                                        throw PlayCoverError.runtimeError("Currently implementation of this method is not exposed")
                                    }
                                    
                                    var ext = fileURL.pathExtension
                                    shell("rm \(oldPath)")
                                    if ext.isEmpty{
                                        shell("mv \(newPath) \(oldPath)")
                                    } else{
                                        shell("mv \(newPath) \(oldPath)")
                                    }
                                    if exec{
                                        shell("chmod 755 \(oldPath)")
                                    }
                                    print(shell("vtool -arch arm64 -set-build-version maccatalyst 10.0 14.5 -replace -output \(fileURL.path) \(fileURL.path)"))
                                    print(shell("codesign -fs- \(oldPath)"))
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
    
    static func extractAppFromIPA(url : URL) -> (URL?, String, Bool){
        var localLog = ""
        var newZipurl = getDocs().appendingPathComponent(url.lastPathComponent)
        print(newZipurl)
        localLog.append(shell("cp \(url.path) \(newZipurl.path)"))
        let newURL = newZipurl.deletingPathExtension().appendingPathExtension("zip")
        print(newURL)
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
        } catch {
            print("this will never happen")
        }
        shell("unzip \(newURL.path) -d \(getDocs().path)")
        
        func clearCache(){
            shell("rm \(newZipurl.path)")
            shell("rm \(newURL.path)")
        }
        
        do {
            let targetUrl = try (getDocs().appendingPathComponent("Payload", isDirectory: true).subDirectories())[0]
            clearCache()
            return (targetUrl, localLog, true)
        } catch {
            clearCache()
            localLog.append("IPA file is corrupted. No .app directory found.")
            return (URL(fileURLWithPath: ""), localLog, false)
        }
    }
    
    static func copyApp(url : URL, returnCompletion: @escaping (Return) -> ()){
        DispatchQueue.global(qos: .background).async {
            var outputLog = ""
            let newPath = getDocs()
            var success = false
            var targetURL : URL? = url
            
            (targetURL,outputLog, success) = extractAppFromIPA(url: url)
            
            if !success{
                returnCompletion(Return(app: nil, log: outputLog, success: false))
            }
            
            if !FileManager.default.fileExists(atPath: newPath.path) {
                do {
                    try FileManager.default.createDirectory(atPath: newPath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    outputLog.append(error.localizedDescription)
                    returnCompletion(Return(app: nil, log: outputLog, success: false))
                }
            }
            
            if let innerUrl = targetURL{
                outputLog.append(shell("cp -R \(innerUrl.path) \(newPath.path)"))
                print("foo \(innerUrl.deletingLastPathComponent())")
                shell("rm -R \(innerUrl.deletingLastPathComponent().path)")
                let appPath = newPath.appendingPathComponent(innerUrl.lastPathComponent).path
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
                outputLog.append(shell("rm \(ents.path)"))
                returnCompletion(Return(app: AppModel(name: innerUrl.lastPathComponent, path: newPath.appendingPathComponent(innerUrl.lastPathComponent), icon: iconUrl, downloaded: true), log: outputLog, success: true))
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
