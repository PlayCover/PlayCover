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
            
            var tempDir : URL? = nil
            
            do {
                tempDir = try createTempFolder()
                let ipaFile = try copyIPAToTempFolder(temp: tempDir)
                let appDir = try unzipIPA(ipa: ipaFile)
                let infoPlist = getInfoPlist(app: appDir)
                let appName = try getAppName(plist : infoPlist)
                if userData.makeFullscreen{
                    try fullscreenAndControls(app: appDir, name: appName)
                }
                try convertApp(app: appDir)
                try fixExecutable(app: appDir, name: appName)
                //try patchMinVersion(info: infoPlist)
                try signApp(app: appDir, appName: appName)
                disableFileLock(url: appDir)
                let docAppDir = try placeAppToDocs(app: appDir, name: appName)
                clearCache(temp: tempDir!)
                returnCompletion(docAppDir)
            } catch {
                ulog(str: error.localizedDescription)
                if let tmp = tempDir{
                    clearCache(temp: tmp)
                }
                returnCompletion(nil)
            }
            
            func createTempFolder() throws -> URL {
                ulog(str: "Creating temp directory\n")
                let tempDir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent(UUID().uuidString)
                try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: [:])
                return tempDir
            }
            
            func clearCache(temp: URL){
                ulog(str: "Clearing cache\n")
                do{
                    try fm.removeItem(at: temp)
                } catch{
                    
                }
            }
            
            func copyIPAToTempFolder(temp: URL?) throws -> URL {
                let ipa = temp!.appendingPathComponent("ipafile.ipa")
                ulog(str: "Copying .ipa to temp folder\n")
                try secureCopyItem(at: url, to: ipa)
                return ipa
            }
            
            func unzipIPA(ipa : URL) throws -> URL {
                ulog(str: "Unzipping .ipa\n")
                let zip = ipa.deletingPathExtension().appendingPathExtension("zip")
                let unzip = zip.deletingPathExtension()
                try fm.moveItem(at: ipa, to: zip)
                try Zip.unzipFile(zip, destination: unzip, overwrite: true, password: nil)
                return try unzip.appendingPathComponent("Payload").subDirectories()[0]
            }
            
            func disableFileLock(url : URL){
                ulog(str: "Disabling quarantine\n")
                ulog(str: shell("xattr -rd com.apple.quarantine \(url.path)"))
            }
            
            func convertApp(app : URL) throws{
                ulog(str: "Converting app\n")
                let files = [URL]()
                if let enumerator = fm.enumerator(at: app, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
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
                
                if convert(fileUrl.path) == -1{
                    try fm.copyItem(at: fileUrl, to: newURL)
                    shell("vtool -arch arm64 -set-build-version maccatalyst 13.0 15.0 -replace -output \(newURL.path) \(newURL.path)")
                }
                
                ulog(str: shell("codesign -fs- \(newURL.path)"))
                
                try fm.removeItem(at: fileUrl)
                try fm.moveItem(at: newURL, to: fileUrl)
            }
            
            func secureCopyItem(at srcURL: URL, to dstURL: URL) throws{
                if fm.fileExists(atPath: dstURL.path) {
                    try fm.removeItem(at: dstURL)
                }
                try fm.copyItem(at: srcURL, to: dstURL)
            }
            
            func getInfoPlist(app: URL) -> URL {
                return app.appendingPathComponent("Info.plist")
            }
            
            func getAppName(plist: URL) throws -> String {
                ulog(str: "Rietriving app name\n")
                return (NSDictionary(contentsOfFile: plist.path)!["CFBundleExecutable"] as! String?)!
            }
            
            func placeAppToDocs(app : URL, name: String) throws -> URL {
                ulog(str: "Importing app to Documents\n")
                let docApp = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent(name).appendingPathComponent(app.lastPathComponent)
                
                if fm.fileExists(atPath: docApp.path){
                    try fm.removeItem(at: docApp)
                }
                try fm.createDirectory(at: docApp.deletingPathExtension().deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try fm.moveItem(at: app, to: docApp)
                return docApp
            }
            
            func fixExecutable(app: URL, name : String) throws {
                ulog(str: "Fixing executable\n")
                let executableFile = app.appendingPathComponent(name)
                var attributes = [FileAttributeKey : Any]()
                attributes[.posixPermissions] = 0o755
                try fm.setAttributes(attributes, ofItemAtPath: executableFile.path)
            }
            
            func signApp(app : URL, appName : String) throws {
                ulog(str: "Signing app\n")
                let ents = try createEntitlements(app: app, name: appName)
                ulog(str: shell("codesign -fs- \(app.path) --deep --entitlements \(ents.path)"))
                try fm.removeItem(at: ents)
            }
            
            func createEntitlements(app: URL, name : String) throws -> URL{
                ulog(str: "Creating entitlements file\n")
                let ents = app.deletingLastPathComponent().appendingPathComponent("ent.plist")
                if userData.fixLogin{
                    try copyEntitlements(app: app, name: name).write(to: ents, atomically: true, encoding: String.Encoding.utf8)
                } else{
                    try entitlements_template.write(to: ents, atomically: true, encoding: String.Encoding.utf8)
                }
                return ents
            }
            
            func copyEntitlements(app: URL, name : String) throws -> String{
                ulog(str: "Copying entitlements \n")
                let executablePath = app.appendingPathComponent(name).path
                print(shell("codesign -d --entitlements :- \(executablePath)"))
                var en = shell("codesign -d --entitlements :- \(executablePath)")
                if !en.contains("DOCTYPE plist PUBLIC"){
                    en = entitlements_template
                }
                print(en)
                return en
            }
            
            func ulog(str : String = "Unknown error!"){
                DispatchQueue.main.async {
                    userData.log.append(str)
                }
            }
            
            func patchMinVersion(info : URL) throws {
                let plist = NSDictionary(contentsOfFile: info.path)
                let dict = (plist! as NSDictionary).mutableCopy() as! NSMutableDictionary
                if let val = dict["MinimumOSVersion"] {
                    dict["MinimumOSVersion"] = 11
                }
                dict.write(toFile: info.path, atomically: true)
            }
            
            func fullscreenAndControls(app : URL, name : String) throws {
                ulog(str: "Adding PlayCover\n")
                let playCover = Bundle.main.url(forResource: "PlayCoverInject", withExtension: "")
                let macHelper = Bundle.main.url(forResource: "MacHelper", withExtension: "")
                let pc = app.appendingPathComponent(playCover!.lastPathComponent)
                let mh = app.appendingPathComponent(macHelper!.lastPathComponent)

                try fm.copyItem(at: playCover!, to: pc)
                try fm.copyItem(at: macHelper!, to: mh)
                
                let optool = Bundle.main.url(forResource: "optool", withExtension: "")
                if !fm.isExecutableFile(atPath: optool!.path){
                    var attributes = [FileAttributeKey : Any]()
                    attributes[.posixPermissions] = 0o755
                    try fm.setAttributes(attributes, ofItemAtPath: optool!.path)
                }
                
                let executablePath = app.appendingPathComponent(name)
                ulog( str: shell("\(optool!.path) install -p \"@executable_path/PlayCoverInject\" -t \(executablePath.path)"))
                ulog( str: shell("\(optool!.path) install -p \"@executable_path/MacHelper\" -t \(executablePath.path)"))
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
