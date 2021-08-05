//
//  AppCreator.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation
import Zip

class AppCreator {
    
    enum PlayCoverError: Error {
        case cantCreateTemp
        case ipaCorrupted
    }
    
    static let possibleHeaders : [Array<UInt8>] = [
        [202,254,186, 190],
        [207 ,250 ,237 ,254]
    ]
    
    static func handleApp(url : URL, userData : UserData, returnCompletion: @escaping (URL?) -> ()){
        
        DispatchQueue.global(qos: .background).async {
            
            let fm = FileManager.default
            
            var tempDir = URL(fileURLWithPath: "")
            var ipaFile = URL(fileURLWithPath: "")
            var zipFile = URL(fileURLWithPath: "")
            var unzippedDir = URL(fileURLWithPath: "")
            var appDir = URL(fileURLWithPath: "")
            var infoPlistFile = URL(fileURLWithPath: "")
            var ents = URL(fileURLWithPath: "")
            var docAppDir = URL(fileURLWithPath: "")
            var appName = "App"
            
            do {
                try createTempFolder()
                try copyIPAToTempFolder()
                try unzipIPA()
                try convertApp()
                getInfoPlist()
                try getAppName()
                try placeAppToDocs()
                clearCache()
                disableFileLock(url: docAppDir)
                try fixExecutable()
                try patchMinVersion()
                if userData.makeFullscreen{
                    try fullscreenAndControls()
                }
                try signApp()
                returnCompletion(docAppDir)
            } catch {
                ulog(str: error.localizedDescription)
                clearCache()
                returnCompletion(nil)
            }
            
            func createTempFolder() throws{
                ulog(str: "Creating temp directory\n")
                tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                ipaFile = tempDir.appendingPathComponent("ipafile.ipa")
                try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: [:])
            }
            
            func clearCache(){
                ulog(str: "Clearing cache\n")
                do{
                    try fm.removeItem(at: tempDir)
                } catch{
                    
                }
            }
            
            func copyIPAToTempFolder() throws {
                ulog(str: "Copying .ipa to temp folder\n")
                try secureCopyItem(at: url, to: ipaFile)
            }
            
            func unzipIPA() throws {
                ulog(str: "Unzipping .ipa\n")
                zipFile = ipaFile.deletingPathExtension().appendingPathExtension("zip")
                unzippedDir = zipFile.deletingPathExtension()
                try fm.moveItem(at: ipaFile, to: zipFile)
                try Zip.unzipFile(zipFile, destination: unzippedDir, overwrite: true, password: nil)
            }
            
            func disableFileLock(url : URL){
                ulog(str: "Disabling quarantine\n")
                ulog(str: shell("xattr -rd com.apple.quarantine \(url.path)"))
            }
            
            func convertApp() throws {
                ulog(str: "Converting app\n")
                appDir = try unzippedDir.appendingPathComponent("Payload").subDirectories()[0]
                var files = [URL]()
                if let enumerator = fm.enumerator(at: appDir, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                    for case let fileURL as URL in enumerator {
                        do {
                            let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                            if fileAttributes.isRegularFile! {
                                if checkIfFileMacho(fileUrl: fileURL){
                                    try convertBinary(fileUrl: fileURL)
                                }
                            }
                        }
                    }
                }
            }
            
            func checkIfFileMacho(fileUrl : URL) -> Bool {
                if let bts = bytesFromFile(filePath: fileUrl.path){
                    if bts.count > 4{
                        let header = bts[...3]
                        let exec = fm.isExecutableFile(atPath: fileUrl.path)
                        if header.count == 4{
                            if(possibleHeaders.contains(Array(header)) || fileUrl.pathExtension.contains("dylib") || exec){
                                return true
                            }
                        }
                    }
                }
                return false
            }
            
            func convertBinary(fileUrl : URL) throws {
                ulog(str: "Converting \(fileUrl.lastPathComponent)\n")
                let newURL = URL(fileURLWithPath: fileUrl.path.appending("_sim"))
                try fm.copyItem(at: fileUrl, to: newURL)
                
                if convert(fileUrl.path) == -24{
                    
                }
                
                try fm.removeItem(at: fileUrl)
                try fm.moveItem(at: newURL, to: fileUrl)
                
                ulog(str: shell("vtool -arch arm64 -set-build-version maccatalyst 13.0 15.0 -replace -output \(fileUrl.path) \(fileUrl.path)"))
                ulog(str: shell("codesign -fs- \(fileUrl.path)"))
            }
            
            func secureCopyItem(at srcURL: URL, to dstURL: URL) throws{
                if fm.fileExists(atPath: dstURL.path) {
                    try fm.removeItem(at: dstURL)
                }
                try fm.copyItem(at: srcURL, to: dstURL)
            }
            
            func getInfoPlist() {
                infoPlistFile = appDir.appendingPathComponent("Info.plist")
            }
            
            func getAppName() throws {
                ulog(str: "Rietriving app name\n")
                appName = (NSDictionary(contentsOfFile: infoPlistFile.path)!["CFBundleExecutable"] as! String?)!
            }
            
            func placeAppToDocs() throws {
                ulog(str: "Importing app to Documents\n")
                docAppDir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent(appName).appendingPathComponent(appDir.lastPathComponent)
                
                if fm.fileExists(atPath: docAppDir.path){
                    try fm.removeItem(at: docAppDir)
                }
                try fm.createDirectory(at: docAppDir.deletingPathExtension().deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try fm.moveItem(at: appDir, to: docAppDir)
            }
            
            func fixExecutable() throws {
                ulog(str: "Fixing executable\n")
                let executableFile = docAppDir.appendingPathComponent(appName)
                var attributes = [FileAttributeKey : Any]()
                attributes[.posixPermissions] = 0o755
                try fm.setAttributes(attributes, ofItemAtPath: executableFile.path)
            }
            
            func signApp() throws {
                ulog(str: "Signing app\n")
                try createEntitlements()
                ulog(str: shell("codesign -fs- \(docAppDir.path) --deep --entitlements \(ents.path)"))
                try fm.removeItem(at: ents)
            }
            
            func createEntitlements() throws {
                ulog(str: "Creating entitlements file\n")
                ents = docAppDir.deletingLastPathComponent().appendingPathComponent("ent.plist")
                try entitlements_template.write(to: ents, atomically: true, encoding: String.Encoding.utf8)
            }
            
            func ulog(str : String = "Unknown error!"){
                DispatchQueue.main.async {
                    userData.log.append(str)
                }
            }
            
            func patchMinVersion() throws {
                infoPlistFile = docAppDir.appendingPathComponent("Info.plist")
                let plist = NSDictionary(contentsOfFile: infoPlistFile.path)
                let dict = (plist! as NSDictionary).mutableCopy() as! NSMutableDictionary
                if let val = dict["MinimumOSVersion"] as? Int{
                    if val > 11{
                        dict["MinimumOSVersion"] = 11
                    }
                }
                dict.write(toFile: infoPlistFile.path, atomically: true)
            }
            
            func fullscreenAndControls() throws {
                let playCover = Bundle.main.url(forResource: "PlayCoverInject", withExtension: "")
                let macHelper = Bundle.main.url(forResource: "MacHelper", withExtension: "")
                let pc = docAppDir.appendingPathComponent(playCover!.lastPathComponent)
                let mh = docAppDir.appendingPathComponent(macHelper!.lastPathComponent)

                try fm.copyItem(at: playCover!, to: pc)
                try fm.copyItem(at: macHelper!, to: mh)
                
                let optool = Bundle.main.url(forResource: "optool", withExtension: "")
                if !fm.isExecutableFile(atPath: optool!.path){
                    var attributes = [FileAttributeKey : Any]()
                    attributes[.posixPermissions] = 0o755
                    try fm.setAttributes(attributes, ofItemAtPath: optool!.path)
                }
                
                let executablePath = docAppDir.appendingPathComponent(appName)
                ulog( str: shell("\(optool!.path) install -p \"@executable_path/PlayCoverInject\" -t \(executablePath)"))
                ulog( str: shell("\(optool!.path) install -p \"@executable_path/MacHelper\" -t \(executablePath)"))
            }
            
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
