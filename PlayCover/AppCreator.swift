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
    let app : AppModel
    let log : String
    init(app : AppModel, log : String) {
        self.app = app
        self.log = log
    }
}

class AppCreator {
    
    static func convertApp(url : URL){
        var files = [URL]()
        
        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        var oldPath = fileURL.path.replacingOccurrences(of: " ", with: "\\ ")
                        if var bts = bytesFromFile(filePath: fileURL.path){
                            if bts.count > 2{
                                if(bts[0] == 207 && bts[1] == 250){
                                    var exec = FileManager.default.isExecutableFile(atPath: oldPath)
                                    
                                    shell("cp \(oldPath) \(oldPath)_sim")
                                    var newPath = oldPath.appending("_sim")
                                    
                                    convert(fileURL.path)
                                    
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
                                    print(shell("codesign --remove-signature \(oldPath)"))
                                }
                            }
                            
                        }
                    }
                } catch { print(error, fileURL) }
            }
        }
    }
    
    static func copyApp(url : URL, returnCompletion: @escaping (Return) -> ()){
        DispatchQueue.global(qos: .background).async {
            var outputLog = ""
            let newPath = getDocs()
            if !FileManager.default.fileExists(atPath: newPath.path) {
                do {
                    try FileManager.default.createDirectory(atPath: newPath.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error.localizedDescription)
                }
            }
            
            outputLog.append(shell("cp -R \(url.path) \(newPath.path)"))
            let appPath = newPath.appendingPathComponent(url.lastPathComponent).path
            outputLog.append("Removing app from quarantine\n")
            outputLog.append(shell("xattr -rd com.apple.quarantine \(appPath)"))
            outputLog.append("Converting app\n")
            convertApp(url: newPath.appendingPathComponent(url.lastPathComponent))
            outputLog.append("Fixing executable\n")
            let plistUrl = newPath.appendingPathComponent(url.lastPathComponent).appendingPathComponent("Info.plist")
            var iconUrl = newPath.appendingPathComponent(url.lastPathComponent).appendingPathComponent("AppIcon60x60@2x.png")
            if let iconName = getIconNameFromPlist(url: plistUrl){
                iconUrl = newPath.appendingPathComponent(url.lastPathComponent).appendingPathComponent(iconName)
            }
            if let execName = getExecutableNameFromPlist(url: plistUrl){
                let execpath = newPath.appendingPathComponent(url.lastPathComponent).appendingPathComponent(execName).path
                outputLog.append(shell("chmod 755 \(execpath)"))
            }
            outputLog.append("Codesigning\n")
            let ents = createEntitlements()
            outputLog.append(shell("codesign -fs- \(newPath.appendingPathComponent(url.lastPathComponent).path) --deep --entitlements \(ents.path)"))
            outputLog.append(shell("rm \(ents.path)"))
            returnCompletion(Return(app: AppModel(name: url.lastPathComponent, path: newPath.appendingPathComponent(url.lastPathComponent), icon: iconUrl, downloaded: true), log: outputLog))
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
