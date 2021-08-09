//
//  AppCreator.swift
//  PlayCover
//

import Foundation
import Zip

class AppInstaller {
    
    static let shared = AppInstaller()
    
    required init() {}
    
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
                    if !isSIPEnabled(){
                        throw PlayCoverError.sipDisabled
                    }
                    try decryptApp(app: appDir, temp: tempDir!, name: appName, bundleName: bundleName, exec: execFile)
                }
                
                if vm.makeFullscreen{
                    try fullscreenAndControls(app: appDir, exec: execFile)
                }
                try BinaryPatcher.patchApp(app: appDir)
                
                try fixExecutable(exec: execFile)
                try infoPlist.patchMinVersion()
                disableFileLock(url: appDir)
                try signApp(app: appDir, ents: ents)
                let docAppDir = try placeAppToDocs(app: appDir, name: appName)
                fm.clearCache()
                returnCompletion(docAppDir, "")
            } catch {
                var errorMessage = ""
                if case PlayCoverError.cantDecryptIpa = error {
                    errorMessage = "This .IPA can't be decrypted on this Mac. Download this .ipa from AppDb.to"
                } else if case PlayCoverError.infoPlistNotFound = error{
                    errorMessage = "This .IPA is courrupted. It doesn't contains Info.plist."
                } else if case PlayCoverError.sipDisabled = error{
                    errorMessage = "It it impossible to decrypt .IPA with SIP disabled. Please, enable it."
                } else{
                    errorMessage = error.localizedDescription
                }
                ulog(error.localizedDescription)
                fm.clearCache()
                returnCompletion(nil, errorMessage)
            }
            
            func createTempFolder() throws -> URL {
                ulog("Creating temp directory\n")
                let tempDir = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent("temp")
                    .appendingPathComponent(UUID().uuidString)
                try? fm.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: [:])
                return tempDir
            }
            
            func copyIPAToTempFolder(temp: URL?) throws -> URL {
                let ipa = temp!.appendingPathComponent("ipafile.ipa")
                ulog("Copying .ipa to temp folder\n")
                try fm.copy(at: url, to: ipa)
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
            
            func isIPAEncrypted(exec: URL) -> Bool {
                let response = shell("otool -l \(exec.esc) | grep LC_ENCRYPTION_INFO -A5")
                return response.contains("cryptid 1")
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
                
                if isIPAEncrypted(exec: targetExecFile){
                    ulog("This IPA can't be decrypted on Mac\n")
                    throw PlayCoverError.cantDecryptIpa
                }
                
                try fm.delete(at: app)
                ulog(shell("cp -R /Applications/\(bundleName.esc).app/Wrapper/\(name.esc).app \(tempDir!.esc)/ipafile/Payload/"))
                try fm.delete(at: exec)
                try fm.copyItem(at: targetExecFile, to: exec)
                if !isDecryptMethod2 {
                    ulog(shell("rm -rf /Applications/\(bundleName.esc).app/"))
                }
            }
            
            func unpackAppToAppsDir(app : URL, temp : URL, name : String, bundleName : String) throws {
                let finalProduct = temp.appendingPathComponent("\(bundleName).app")
                try fm.delete(at: finalProduct)
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
                while( try fm.filesCount(inDir: inAppDir) < originalFilesCount){
                    usleep(1000000)
                    secs+=1
                    if secs > 120{
                        throw PlayCoverError.cantDecryptIpa
                    }
                }
            }
            
            func placeAppToDocs(app : URL, name: String) throws -> URL {
                ulog("Importing app to Documents\n")
                let docApp = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover").appendingPathComponent(name).appendingPathComponent(app.lastPathComponent)
                
                try fm.delete(at: docApp)
                
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
                if let util = Bundle.main.url(forResource: utilName, withExtension: ""){
                    if !fm.isExecutableFile(atPath: util.path){
                        try fixExecutable(exec: util)
                    }
                    return util
                }
                throw PlayCoverError.ipaCorrupted
            }
            
        }
        
    }
    
}
