//
//  AppCreator.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation
import Zip

class AppInstaller {
    
    static let shared = AppInstaller()
    
    required init() {}

    static let possibleHeaders : [Array<UInt8>] = [
        [202, 254, 186, 190],
        [207, 250, 237, 254]
    ]
    
    func installApp(url : URL, returnCompletion: @escaping (URL?, String) -> ()){
        
        DispatchQueue.global(qos: .background).async {
            
            var tempDir : URL? = nil
            
            do {
                shell("vtool -h")
                tempDir = try createTempFolder()
                let ipaFile = try copyIPAToTempFolder(temp: tempDir)
                let appDir = try unzipIPA(ipa: ipaFile)
                let infoPlist = try InfoPlist.readInfoPlist(app: appDir)
                let appName = try infoPlist.appName()
                let bundleName = try infoPlist.bundleName()
                let execFile = appDir.appendingPathComponent(appName )
                let ents = try Entitlements.createEntitlements(app: appDir, exec: execFile)
                
                if isIPAEncrypted(exec: execFile){
                    try decryptApp(app: appDir, temp: tempDir!, name: appName, bundleName: bundleName, exec: execFile)
                }
                
                if vm.makeFullscreen{
                    try fullscreenAndControls(app: appDir, exec: execFile)
                }
                
                try convertApp(app: appDir, alternativeWay: vm.useAlternativeWay)
                
                try fixExecutable(exec: execFile)
                try infoPlist.patchMinVersion()
                disableFileLock(url: appDir)
                try signApp(app: appDir, ents: ents)
                let docAppDir = try placeAppToDocs(app: appDir, name: appName)
                clearCache(temp: tempDir!)
                returnCompletion(docAppDir, "")
            } catch {
                var errorMessage = ""
                if case PlayCoverError.cantDecryptIpa = error {
                    errorMessage = "This .IPA can't be decrypted on this Mac. Download this .ipa from AppDb.to"
                } else if case PlayCoverError.infoPlistNotFound = error{
                    errorMessage = "This .IPA is courrupted. It doesn't contains Info.plist. "
                } else{
                    errorMessage = error.localizedDescription
                }
                ulog(error.localizedDescription)
                if let tmp = tempDir{
                    clearCache(temp: tmp)
                }
                returnCompletion(nil, errorMessage)
            }
            
            func createTempFolder() throws -> URL {
                ulog("Creating temp directory\n")
                let tempDir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent(UUID().uuidString)
                try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: [:])
                return tempDir
            }
            
            func clearCache(temp: URL){
                ulog("Clearing cache\n")
                do{
                    try fm.removeItem(at: temp)
                } catch{
                    
                }
            }
            
            func copyIPAToTempFolder(temp: URL?) throws -> URL {
                let ipa = temp!.appendingPathComponent("ipafile.ipa")
                ulog("Copying .ipa to temp folder\n")
                try secureCopyItem(at: url, to: ipa)
                return ipa
            }
            
            func unzipIPA(ipa : URL) throws -> URL {
                ulog("Unzipping .ipa\n")
                let zip = ipa.deletingPathExtension().appendingPathExtension("zip")
                let unzip = zip.deletingPathExtension()
                try fm.moveItem(at: ipa, to: zip)
                try Zip.unzipFile(zip, destination: unzip, overwrite: true, password: nil)
                return try unzip.appendingPathComponent("Payload").subDirectories()[0]
            }
            
            func disableFileLock(url : URL){
                ulog("Disabling quarantine\n")
                ulog(shell("xattr -rds com.apple.quarantine \(url.esc)"))
            }
            
            func convertApp(app : URL, alternativeWay : Bool) throws{
                ulog("Converting app\n")
                if let enumerator = fm.enumerator(at: app, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
                    for case let fileURL as URL in enumerator {
                        do {
                            let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                            if fileAttributes.isRegularFile! {
                                if checkIfFileMacho(fileUrl: fileURL){
                                    try convertBinary(fileUrl: fileURL, useAlternative: alternativeWay)
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
                    ulog("Clearing \(url.esc)\n")
                    do {
                        try FileManager.default.removeItem(atPath: url.path)
                    } catch{
                        
                    }
                }
            }
            
            func decryptApp(app : URL, temp : URL, name : String, bundleName : String, exec : URL) throws {
                ulog("IPA is encrypted, trying to decrypt\n")
                try unpackAppToAppsDir(app: app, temp: temp, name: name, bundleName: bundleName)
                let sourceExecFile = URL(fileURLWithPath: "/Applications/\(bundleName).app/Wrapper/\(name).app/\(name)", isDirectory: false)
                let targetExecFile = tempDir!.appendingPathComponent(name, isDirectory: false)
                let crypt = try makeUtilExecutable(utilName: "appdecrypt")
                var isDecryptMethod2 = false
                
                ulog(shell("\(crypt.esc) \(sourceExecFile.esc) \(targetExecFile.esc)"))
                if isIPAEncrypted(exec: targetExecFile){
                    ulog("IPA is still encrypted, trying again\n")
                    ulog(shell("\(crypt.esc) \(sourceExecFile.esc) \(targetExecFile.esc)"))
                }
                
                if isIPAEncrypted(exec: targetExecFile){
                    ulog(shell("rm -rf /Applications/\(bundleName.esc).app/"))
                    isDecryptMethod2 = true
                    try installIPA(origipa: url, inAppDir: URL(fileURLWithPath: "/Applications/\(bundleName).app/Wrapper/\(name).app"), tempApp: app)
                    ulog(shell("\(crypt.esc) \(sourceExecFile.esc) \(targetExecFile.esc)"))
                }
                
//                if isIPAEncrypted(exec: targetExecFile){
//                    ulog("This IPA can't be decrypted on Mac\n")
//                    throw PlayCoverError.cantDecryptIpa
//                }
                
                try deleteFolder(at: app)
                ulog(shell("cp -R /Applications/\(bundleName.esc).app/Wrapper/\(name.esc).app \(tempDir!.esc)/ipafile/Payload/"))
                try deleteFolder(at: exec)
                try fm.copyItem(at: targetExecFile, to: exec)
                if !isDecryptMethod2 {
                    ulog(shell("rm -rf /Applications/\(bundleName.esc).app/"))
                }
            }
            
            func unpackAppToAppsDir(app : URL, temp : URL, name : String, bundleName : String) throws {
                let finalProduct = temp.appendingPathComponent("\(bundleName).app")
                try deleteFolder(at: finalProduct)
                ulog("Creating Wrapper folder\n")
                let wrapperPath = finalProduct.appendingPathComponent("Wrapper")
                try FileManager.default.createDirectory(atPath: wrapperPath.path, withIntermediateDirectories: true, attributes: nil)
                ulog("Wrapper path: \(wrapperPath)\n")
                
                ulog("Copying files\n")
                try FileManager.default.copyItem(
                    atPath: app.path,
                    toPath: wrapperPath.appendingPathComponent(app.lastPathComponent).path
                )
                ulog("Creating symbolic link\n")
                try FileManager.default.createSymbolicLink(
                    atPath: finalProduct.appendingPathComponent("WrappedBundle").path,
                    withDestinationPath: "Wrapper/\(app.lastPathComponent)"
                )
                shell("xattr -dr com.apple.quarantine \(finalProduct.esc)")
                ulog("Moving to /Applications \n")
                shell("mv \(finalProduct.esc) /Applications")
            }
            
            func installIPA(origipa: URL, inAppDir: URL, tempApp: URL) throws {
                ulog("Decrypting using alternative way\n")
                let originalFilesCount = try fm.contentsOfDirectory(atPath: tempApp.path).count
                shell("open -a iOS\\ App\\ Installer.app \(origipa.esc)")
                var secs = 0
                while( try filesCount(inDir: inAppDir) < originalFilesCount){
                    usleep(1000000)
                    secs+=1
                    if secs > 120{
                        throw PlayCoverError.cantDecryptIpa
                    }
                }
            }
            
            func filesCount(inDir: URL) throws -> Int{
                if fm.fileExists(atPath: inDir.path){
                    return try fm.contentsOfDirectory(atPath: inDir.path).count
                }
                return 0
            }
            
            func checkIfFileMacho(fileUrl : URL) -> Bool {
                if !fileUrl.pathExtension.isEmpty && fileUrl.pathExtension != "dylib" {
                    return false
                }
                if let bts = bytesFromFile(filePath: fileUrl.path){
                    if bts.count > 4{
                        let header = bts[...3]
                        if header.count == 4{
                            if(AppInstaller.possibleHeaders.contains(Array(header))){
                                return true
                            }
                        }
                    }
                }
                return false
            }
            
            func convertBinary(fileUrl : URL, useAlternative : Bool) throws {
                ulog("Converting \(fileUrl.lastPathComponent)\n")
                if useAlternative {
                    try internalWay()
                } else{
                    vtoolWay()
                }
                
                ulog(shell("codesign -fs- \(fileUrl.esc)"))
                
                func vtoolWay(){
                    shell("vtool -arch arm64 -set-build-version maccatalyst 10.0 14.5 -replace -output \(fileUrl.esc) \(fileUrl.esc)")
                }
                
                func internalWay() throws {
                    convert(fileUrl.path.esc)
                    let newUrl = fileUrl.path.appending("_sim")
                    
                    try deleteFolder(at: fileUrl)
                    try fm.moveItem(atPath: newUrl, toPath: fileUrl.path)
                }
                
            }
            
            func secureCopyItem(at srcURL: URL, to dstURL: URL) throws{
                if fm.fileExists(atPath: dstURL.path) {
                    try fm.removeItem(at: dstURL)
                }
                try fm.copyItem(at: srcURL, to: dstURL)
            }
            
            func placeAppToDocs(app : URL, name: String) throws -> URL {
                ulog("Importing app to Documents\n")
                let docApp = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent(name).appendingPathComponent(app.lastPathComponent)
                
                try deleteFolder(at: docApp)
                
                try fm.createDirectory(at: docApp.deletingPathExtension().deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                try fm.moveItem(at: app, to: docApp)
                return docApp
            }
            
            func fixExecutable(exec : URL) throws {
                ulog("Fixing executable\n")
                var attributes = [FileAttributeKey : Any]()
                attributes[.posixPermissions] = 0o777
                try fm.setAttributes(attributes, ofItemAtPath: exec.path)
            }
            
            func signApp(app : URL, ents : URL) throws {
                ulog("Signing app\n")
                ulog(shell("codesign -fs- \(app.esc) --deep --entitlements \(ents.esc)"))
            }
            
            func fullscreenAndControls(app : URL, exec : URL) throws {
                ulog("Adding PlayCover\n")
                let playCover = Bundle.main.url(forResource: "PlayCoverInject", withExtension: "")
                let macHelper = Bundle.main.url(forResource: "MacHelper", withExtension: "")
                let pc = app.appendingPathComponent(playCover!.lastPathComponent)
                let mh = app.appendingPathComponent(macHelper!.lastPathComponent)
                
                try fm.copyItem(at: playCover!, to: pc)
                try fm.copyItem(at: macHelper!, to: mh)
                
                let optool = try makeUtilExecutable(utilName: "optool")
                
                ulog( shell("\(optool.esc) install -p \"@executable_path/PlayCoverInject\" -t \(exec.esc)"))
                ulog( shell("\(optool.esc) install -p \"@executable_path/MacHelper\" -t \(exec.esc)"))
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
    
}
