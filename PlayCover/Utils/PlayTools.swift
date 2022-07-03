//
//  PlayTools.swift
//  PlayCover
//

import Foundation

class PlayTools {
    
    static func replaceLibraries(atURL url: URL) throws {
        Log.shared.log("Replacing libswiftUIKit.dylib")
        _ = try sh.shello(
            install_name_tool.path ,
            "-change", "@rpath/libswiftUIKit.dylib", "/System/iOSSupport/usr/lib/swift/libswiftUIKit.dylib",
            url.path
        )
    }
    
    static func installFor(_ exec : URL, resign : Bool = false) throws {
        patch_binary_with_dylib(exec.path, PLAY_TOOLS_PATH)
        if resign{
            sh.signApp(exec)
        }
    }
    
    static func injectFor(_ exec : URL, payload : URL) throws {
        patch_binary_with_dylib(exec.path, "@executable_path/Frameworks/PlayTools.dylib")
        try injectPlayTools(payload)
    }
    
    static func deleteFrom(_ exec : URL) throws {
        remove_play_tools_from(exec.path, PLAY_TOOLS_PATH)
        sh.signApp(exec)
    }
    
    static func convertMacho(_ macho : URL) throws {
        Log.shared.log("Converting \(macho.lastPathComponent) binary")
        _ = try sh.shello(
            vtool.path,
            "-set-build-version", "maccatalyst", "11.0", "14.0",
            "-replace", "-output",
            macho.path, macho.path
        )
    }
    
    static func isMachoEncrypted(atURL url: URL) throws -> Bool {
        try sh.shello(
            print: false,
            otool.path,
                    "-l", url.path
                ).split(separator: "\n")
                 .first(where: { $0.contains("LC_ENCRYPTION_INFO -A5") })?.contains("cryptid 1") ?? false
    }
    
    static func install(){
        DispatchQueue.global(qos: .background).async {
            do {
                let tools = Bundle.main.url(forResource: "PlayTools", withExtension: "")!
                Log.shared.log("Installing PlayTools")
                try convertMacho(tools)
                sh.codesign(tools)
                if !fm.fileExists(atPath: "/Users/\(NSUserName())/Library/Frameworks"){
                    try fm.createDirectory(atPath: FRAMEWORKS_PATH, withIntermediateDirectories: true, attributes: [:])
                }
                if fm.fileExists(atPath: PLAY_TOOLS_PATH){
                    try fm.delete(at: URL(fileURLWithPath: PLAY_TOOLS_PATH))
                }
                Log.shared.log("Copying PlayTools to Frameworks")
                sh.shell("cp \(tools.esc) \(PLAY_TOOLS_PATH)")
            } catch {
                Log.shared.error(error)
            }
        }
    }
    
    static func injectPlayTools(_ payload : URL) throws{
        DispatchQueue.global(qos: .background).async {
            do {
                let tools = Bundle.main.url(forResource: "PlayTools", withExtension: "")!
                if !FileManager.default.fileExists(atPath: payload.appendingPathComponent("Frameworks").path) {
                    try FileManager.default.createDirectory(at: payload.appendingPathComponent("Frameworks"), withIntermediateDirectories: true)
                }
                let libraryTraget = payload.appendingPathComponent("Frameworks").appendingPathComponent("PlayTools").appendingPathExtension("dylib")
                sh.shell("cp \(tools.esc) \(libraryTraget.esc)")
                try libraryTraget.fixExecutable()
            } catch {
                Log.shared.error(error)
            }
        }
    }
    
    static func isInstalled() throws -> Bool {
        return try fm.fileExists(atPath: PLAY_TOOLS_PATH) && isValidArch(PLAY_TOOLS_PATH)
    }
    
    static func isValidArch(_ path : String) throws -> Bool {
        return try sh.shello(
            vtool.path,
            "-show-build",
            path
        ).contains("MACCATALYST")
    }
    
    private static let PLAY_TOOLS_PATH = "\(FRAMEWORKS_PATH)/\(getSystemUUID()?.prefix(4) ?? "3DEF")N"
    private static let FRAMEWORKS_PATH = "/Users/\(NSUserName())/Library/Frameworks"
    private static let PLAY_COVER_PATH = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/me.playcover.PlayCover")
    
    public static var playCoverContainer : URL {
        
        if !fm.fileExists(atPath: PLAY_COVER_PATH.path){
            do {
                try fm.createDirectory(at: PLAY_COVER_PATH, withIntermediateDirectories: true, attributes: [:])
            } catch{
                Log.shared.error(error)
            }
        }
        
        return PLAY_COVER_PATH
    }
    
    static func getSystemUUID() -> String? {
        let dev = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
        IOObjectRelease(platformExpert)
        if let ser: CFTypeRef = serialNumberAsCFString?.takeUnretainedValue(){
            if let result = ser as? String {
                return result
            }
        }
        return nil
    }
    
    static func fetchEntitlements(_ exec : URL) throws -> String {
        return try sh.shello(
            ldid.path,
            "-e",
            exec.path
        )
    }
    
    private static let vtool : URL = {
        return builtInUtil("vtool")
    }()
    
    private static let otool : URL = {
        return builtInUtil("otool")
    }()
    
    private static let install_name_tool : URL = {
        return builtInUtil("install_name_tool")
    }()
    
    private static let ldid : URL = {
        return builtInUtil("ldid")
    }()
    
    private static func builtInUtil(_ name : String) -> URL{
        let tools = Bundle.main.url(forResource: name, withExtension: "")!
        sh.codesign(tools)
        do {
            try tools.setBinaryPosixPermissions(0x755)
        } catch{
            Log.shared.error(error)
        }
        return tools
    }
    
}

extension URL {
    func setBinaryPosixPermissions(_ permissions: Int) throws {
        try FileManager.default.setAttributes([
            .posixPermissions: permissions
        ], ofItemAtPath: self.path)
    }
}
