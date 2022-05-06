//
//  Shell.swift
//  PlayCover
//

import Foundation

let sh = Shell.self

class Shell : ObservableObject {
    
    static let shared = Shell()
    
    internal static func shello(print : Bool = true, _ binary: String, _ args: String...) throws -> String {
        let process = Process()
        
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let output = try pipe.fileHandleForReading.readToEnd() ?? Data()
        if print {
            Log.shared.log(String(decoding: output, as: UTF8.self))
        }
        return String(decoding: output, as: UTF8.self)
    }
    
    static func isMachoSigned(_ exec : URL) -> Bool {
        return !shell("/usr/bin/codesign -dv \(exec.esc)").contains("code object is not signed at all")
    }
    
    static func codesign(_ binary : URL){
        shell("/usr/bin/codesign -fs- \(binary.esc)")
    }
    
    static func unzip(_ zip : URL, to : URL ){
        shell("unzip \(zip.esc) -d \(to.esc)")
    }
    
    static func signAppWith(_ exec : URL, entitlements : URL){
        shell("/usr/bin/codesign -fs- \(exec.deletingLastPathComponent().esc) --deep --entitlements \(entitlements.esc)")
    }
    
    static func signApp(_ exec : URL){
        shell("/usr/bin/codesign -fs- \(exec.deletingLastPathComponent().esc) --deep --preserve-metadata=entitlements")
    }
    
    static func copyAppToTemp(_ bundleName : String, name : String, temp: URL){
        shell("cp -R /Applications/\(bundleName.esc).app/Wrapper/\(name.esc).app \(temp.esc)/ipafile/Payload/")
    }
    
    static func sudosh(_ args : [String], _ argc : String) -> Bool{
            let password = argc
            let passwordWithNewline = password + "\n"
            let sudo = Process()
            sudo.launchPath = "/usr/bin/sudo"
            sudo.arguments = args
            let sudoIn = Pipe()
            let sudoOut = Pipe()
            sudo.standardOutput = sudoOut
            sudo.standardError = sudoOut
            sudo.standardInput = sudoIn
            sudo.launch()
        
            var result = true

            // Show the output as it is produced
            sudoOut.fileHandleForReading.readabilityHandler = { fileHandle in
                let data = fileHandle.availableData
                if (data.count == 0) { return }
                
                if let out = String(bytes: data, encoding: .utf8){
                    Log.shared.log(out)
                    if out.contains("password"){
                        result = false
                    }
                }
            }
            // Write the password
            sudoIn.fileHandleForWriting.write(passwordWithNewline.data(using: .utf8)!)

            // Close the file handle after writing the password; avoids a
            // hang for incorrect password.
            try? sudoIn.fileHandleForWriting.close()

            // Make sure we don't disappear while output is still being produced.
            sudo.waitUntilExit()
            return result
        }
    
    @discardableResult
    static func shell(_ command: String, print : Bool = true) -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        if print {
            Log.shared.log(output)
        }
      
        return output
    }
    
}


