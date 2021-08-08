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
        [202, 254, 186, 190],
        [207, 250, 237, 254]
    ]
    
    static func handleApp(url : URL, userData : UserData, returnCompletion: @escaping (URL?) -> ()){
        
        DispatchQueue.global(qos: .background).async {
            
            let fm = FileManager.default
            
            var tempDir : URL? = nil
            
            do {
                shell("vtool -h")
                tempDir = try createTempFolder()
                let ipaFile = try copyIPAToTempFolder(temp: tempDir)
                let appDir = try unzipIPA(ipa: ipaFile)
                let infoPlist = getInfoPlist(app: appDir)
                let appName = try getAppName(plist : infoPlist)
                let execFile = appDir.appendingPathComponent(appName)
                let ents = try createEntitlements(app: appDir, exec: execFile)
              
                if isIPAEncrypted(exec: execFile){
                    try decryptApp(app: appDir, temp: tempDir!, name: appName)
                }
                
                if userData.makeFullscreen{
                    try fullscreenAndControls(app: appDir, name: appName)
                }
                
                try convertApp(app: appDir)
               
                try fixExecutable(exec: execFile)
                try patchMinVersion(info: infoPlist)
                disableFileLock(url: appDir)
                try signApp(app: appDir, ents: ents)
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
                ulog(str: shell("xattr -rds com.apple.quarantine \(url.esc)"))
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
            
            func isIPAEncrypted(exec: URL) -> Bool {
                let response = shell("otool -l \(exec.esc) | grep LC_ENCRYPTION_INFO -A5")
                return response.contains("cryptid 1")
            }
            
            func deleteFolder(at url: URL) throws {
                        if FileManager.default.fileExists(atPath: url.path) {
                            ulog(str: "Clearing \(url.esc)\n")
                            try FileManager.default.removeItem(atPath: url.path)
                        }
                    }
            
            func decryptApp(app : URL, temp : URL, name : String) throws {
                ulog(str: "IPA is encrypted, trying to decrypt\n")
                let finalProduct = temp.appendingPathComponent("\(name).app")
                try deleteFolder(at: finalProduct)
                ulog(str: "Creating Wrapper folder\n")
                        let wrapperPath = finalProduct.appendingPathComponent("Wrapper")
                        try FileManager.default.createDirectory(atPath: wrapperPath.path, withIntermediateDirectories: true, attributes: nil)
                     ulog(str: "Wrapper path: \(wrapperPath.esc)\n")
                        
                      ulog(str: "Copying files\n")
                        try FileManager.default.copyItem(
                            atPath: app.path,
                            toPath: wrapperPath.appendingPathComponent(app.lastPathComponent).path
                        )
                ulog(str: "Creating symbolic link\n")
                        try FileManager.default.createSymbolicLink(
                            atPath: finalProduct.appendingPathComponent("WrappedBundle").path,
                            withDestinationPath: "Wrapper/\(app.lastPathComponent)"
                        )
                shell("xattr -dr com.apple.quarantine \(finalProduct.esc)")
                ulog(str: "Moving to /Applications \n")
                shell("mv \(finalProduct.esc) /Applications")
                let sourceExecFile = URL(fileURLWithPath: "/Applications/\(name).app/Wrapper/\(name).app/\(name)", isDirectory: false)
                let targetExecFile = tempDir!.appendingPathComponent(name, isDirectory: false)
                let crypt = try makeUtilExecutable(utilName: "appdecrypt")
                print("\(crypt.esc) \(sourceExecFile.esc) \(targetExecFile.esc)")
                ulog(str: shell("\(crypt.esc) \(sourceExecFile.esc) \(targetExecFile.esc)"))
                try deleteFolder(at: app)
                ulog(str: shell("mv /Applications/\(name.esc).app/Wrapper/\(name.esc).app \(tempDir!.esc)/ipafile/Payload/"))
                try fm.removeItem(at: app.appendingPathComponent(name, isDirectory: false))
                try fm.moveItem(at: targetExecFile, to: app.appendingPathComponent(name, isDirectory: false))
                ulog(str : shell("rm -rf /Applications/\(name.esc).app/"))
            }
            
            func checkIfFileMacho(fileUrl : URL) -> Bool {
                if !fileUrl.pathExtension.isEmpty && fileUrl.pathExtension != "dylib" {
                    return false
                }
                if let bts = bytesFromFile(filePath: fileUrl.path){
                    if bts.count > 4{
                        let header = bts[...3]
                        if header.count == 4{
                            if(possibleHeaders.contains(Array(header))){
                                return true
                            }
                        }
                    }
                }
                return false
            }
            
            func convertBinary(fileUrl : URL) throws {
                ulog(str: "Converting \(fileUrl.lastPathComponent)\n")
                shell("vtool -arch arm64 -set-build-version maccatalyst 10.0 14.5 -replace -output \(fileUrl.esc) \(fileUrl.esc)")
                shell("vtool -arch armv7 -remove-build-version ios -replace -output \(fileUrl.esc) \(fileUrl.esc)")
                ulog(str: shell("codesign -fs- \(fileUrl.esc)"))
            }
            
            func secureCopyItem(at srcURL: URL, to dstURL: URL) throws{
                if fm.fileExists(atPath: dstURL.path) {
                    try fm.removeItem(at: dstURL)
                }
                try fm.copyItem(at: srcURL, to: dstURL)
            }
            
            func getInfoPlist(app: URL) -> URL {
                return app.appendingPathComponent("Info.plist", isDirectory: false)
            }
            
            func getAppName(plist: URL) throws -> String {
                ulog(str: "Rietriving app name\n")
                return (NSDictionary(contentsOfFile: plist.path)!["CFBundleExecutable"] as! String?)!
            }
            
            func placeAppToDocs(app : URL, name: String) throws -> URL {
                ulog(str: "Importing app to Documents\n")
                let docApp = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent(name).appendingPathComponent(app.lastPathComponent)
                
                try deleteFolder(at: docApp)
                
                try fm.createDirectory(at: docApp.deletingPathExtension().deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try fm.moveItem(at: app, to: docApp)
                return docApp
            }
            
            func fixExecutable(exec : URL) throws {
                ulog(str: "Fixing executable\n")
                var attributes = [FileAttributeKey : Any]()
                attributes[.posixPermissions] = 0o777
                try fm.setAttributes(attributes, ofItemAtPath: exec.path)
            }
            
            func signApp(app : URL, ents: URL) throws {
                ulog(str: "Signing app\n")
                ulog(str: shell("codesign -fs- \(app.esc) --deep --entitlements \(ents.esc)"))
                try deleteFolder(at: ents)
            }
            
            func createEntitlements(app: URL, exec : URL) throws -> URL{
                ulog(str: "Creating entitlements file\n")
                let ents = app.deletingLastPathComponent().appendingPathComponent("ent.plist")
                if userData.fixLogin{
                    try copyEntitlements(exec: exec).write(to: ents, atomically: true, encoding: String.Encoding.utf8)
                    try addSandobox(ents: ents)
                } else{
                    try entitlements_template.write(to: ents, atomically: true, encoding: String.Encoding.utf8)
                }
                return ents
            }
            
            func copyEntitlements(exec: URL) throws -> String{
                ulog(str: "Copying entitlements \n")
                var en = excludeEntitlements(from: shell("codesign -d --entitlements :- \(exec.esc)"))
                if !en.contains("DOCTYPE plist PUBLIC"){
                    en = entitlements_template
                }
                return en
            }
            
            func excludeEntitlements(from : String) -> String {
                if let range: Range<String.Index> = from.range(of: "<?xml") {
                    return String(from[range.lowerBound...])
                }
                else {
                    return entitlements_template
                }
            }
            
            func ulog(str : String = "Unknown error!"){
                DispatchQueue.main.async {
                    userData.log.append(str)
                }
            }
            
            func addSandobox(ents : URL) throws {
                ulog(str: "Adding Sandbox\n")
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
            
            func patchMinVersion(info : URL) throws {
                let plist = NSDictionary(contentsOfFile: info.path)
                let dict = (plist! as NSDictionary).mutableCopy() as! NSMutableDictionary
                if Double(dict["MinimumOSVersion"] as! String)! > 11.0 {
                    ulog(str: "Patching Minimum OS version\n")
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
                
                let optool = try makeUtilExecutable(utilName: "optool")
                
                let executablePath = app.appendingPathComponent(name)
                ulog( str: shell("\(optool.esc) install -p \"@executable_path/PlayCoverInject\" -t \(executablePath.esc)"))
                ulog( str: shell("\(optool.esc) install -p \"@executable_path/MacHelper\" -t \(executablePath.esc)"))
            }
            
            func makeUtilExecutable(utilName : String) throws -> URL{
                let util = Bundle.main.url(forResource: utilName, withExtension: "")
                if !fm.isExecutableFile(atPath: util!.path){
                    var attributes = [FileAttributeKey : Any]()
                    attributes[.posixPermissions] = 0o777
                    try fm.setAttributes(attributes, ofItemAtPath: util!.path)
                }
                return util!
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
