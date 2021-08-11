//
//  Shell.swift
//  PlayCover
//

import Foundation

let sh = Shell.self

class Shell {
    
    static func isSIPEnabled() -> Bool{
        return shell("csrutil status").contains("enabled")
    }
    
    static func fetchEntitlements(_ exec : URL) -> String {
        return shell("codesign -d --entitlements :- \(exec.esc)")
    }
    
    static func vtoolPatch(_ binary : URL) {
        shell("vtool -arch arm64 -set-build-version maccatalyst 10.0 14.5 -replace -output \(binary.esc) \(binary.esc)")
    }
    
    static func checkIfXcodeToolsInstalled(){
        shell("vtool -h")
    }
    
    static func codesign(_ binary : URL){
        shell("codesign -fs- \(binary.esc)")
    }
    
    static func removeQuarantine(_ app : URL){
        shell("xattr -rd com.apple.quarantine \(app.esc)")
    }
    
    static func isIPAEncrypted(exec: URL) -> Bool {
        return shell("otool -l \(exec.esc) | grep LC_ENCRYPTION_INFO -A5").contains("cryptid 1")
    }
    
    static func optoolInstall(library : String, exec : URL) {
        shell("\(utils.optool.esc) install -p \"@executable_path/\(library)\" -t \(exec.esc)")
    }
    
    static func signApp(_ app : URL, ents : URL){
        ulog("Signing app\n")
        ulog(shell("codesign -fs- \(app.esc) --deep --entitlements \(ents.esc)"))
    }
    
    static func appdecrypt(_ src : URL, target: URL) {
        ulog(shell("\(utils.crypt.esc) \(src.esc) \(target.esc)"))
    }
    
    static func removeAppFromApps(_ bundleName : String){
        ulog(shell("rm -rf /Applications/\(bundleName.esc).app/"))
    }
    
    static func copyAppToTemp(_ bundleName : String, name : String, temp: URL){
        ulog(shell("cp -R /Applications/\(bundleName.esc).app/Wrapper/\(name.esc).app \(temp.esc)/ipafile/Payload/"))
    }
    
    static func moveAppToApps(_ app : URL){
        ulog("Moving to /Applications \n")
        shell("mv \(app.esc) /Applications")
    }
    
    static func installIPA(_ ipa : URL){
        shell("open -a iOS\\ App\\ Installer.app \(ipa.esc)")
    }
    
    static func fetchAppsBy(_ request : String) -> String {
        return shell("\(utils.ipatool.esc) search \"\(request)\"" )
    }
    
    @discardableResult
    private static func shell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
}


