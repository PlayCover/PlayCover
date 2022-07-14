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
				let tools = URL(fileURLWithPath: BUNDLED_PLAY_TOOLS_FRAMEWORKS_PATH)
                Log.shared.log("Installing PlayTools")
//                try convertMacho(tools)
//                sh.codesign(tools)
                if !fm.fileExists(atPath: FRAMEWORKS_PATH){
                    try fm.createDirectory(atPath: FRAMEWORKS_PATH, withIntermediateDirectories: true, attributes: [:])
                }
                if fm.fileExists(atPath: PLAY_TOOLS_FRAMEWORKS_PATH){
                    try fm.delete(at: URL(fileURLWithPath: PLAY_TOOLS_FRAMEWORKS_PATH))
                }
                Log.shared.log("Copying PlayTools to Frameworks")
                try sh.sh("cp -r \(tools.esc) \(PLAY_TOOLS_FRAMEWORKS_PATH)")
            } catch {
                Log.shared.error(error)
            }
        }
    }
    
    static func injectPlayTools(_ payload : URL) throws{
        DispatchQueue.global(qos: .background).async {
            do {
				let tools = URL(fileURLWithPath: "\(BUNDLED_PLAY_TOOLS_FRAMEWORKS_PATH)/PlayTools")
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
		guard let output = try? sh.shello(vtool.path, "-show-build", path) else {
			return false
		}
		return output.contains("MACCATALYST")
    }
	private static let PLAY_TOOLS_FRAMEWORKS_PATH = "\(FRAMEWORKS_PATH)/PlayTools.framework"
	private static let PLAY_TOOLS_PATH = "\(PLAY_TOOLS_FRAMEWORKS_PATH)/PlayTools"
//    private static let PLAY_TOOLS_PATH = "\(FRAMEWORKS_PATH)/\(getSystemUUID()?.prefix(4) ?? "3DEF")N"
    private static let FRAMEWORKS_PATH = "/Users/\(NSUserName())/Library/Frameworks"
    
    private static let USER_CONTAINER_PATH = "/Users/\(NSUserName())/Library/Containers/"
    private static let PLAY_COVER_DEFAULT_PATH = URL(fileURLWithPath: USER_CONTAINER_PATH + "io.playcover.PlayCover")
	private static let BUNDLED_PLAY_TOOLS_FRAMEWORKS_PATH = "\(Bundle.main.bundlePath)/Contents/Frameworks/PlayTools.framework"
    
    public static var playCoverContainer : URL {
        
        if !fm.fileExists(atPath: PLAY_COVER_DEFAULT_PATH.path){
            do {
                try fm.createDirectory(at: PLAY_COVER_DEFAULT_PATH, withIntermediateDirectories: true, attributes: [:])
            } catch{
                Log.shared.error(error)
            }
        }

        do {
            let redir = try fm.destinationOfSymbolicLink(atPath: PLAY_COVER_DEFAULT_PATH.path)
            
            if redir != "" {
                return URL(fileURLWithPath: USER_CONTAINER_PATH + redir)
            }
        } catch {
            Log.shared.error(error)
        }

        return PLAY_COVER_DEFAULT_PATH
    }
    
//    static func getSystemUUID() -> String? {
//        let dev = IOServiceMatching("IOPlatformExpertDevice")
//        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
//        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
//        IOObjectRelease(platformExpert)
//        if let ser: CFTypeRef = serialNumberAsCFString?.takeUnretainedValue(){
//            if let result = ser as? String {
//                return result
//            }
//        }
//        return nil
//    }
//
//    static func fetchEntitlements(_ exec : URL) throws -> String {
//        return try sh.shello(
//            ldid.path,
//            "-e",
//            exec.path
//        )
//    }

	static func fetchEntitlements(_ exec : URL) throws -> String {
		return try sh.sh("codesign --display --entitlements - --xml '\(exec.path)' | xmllint --format -", pipeStdErr: false)
	}

	private static func binPath(_ bin: String) throws -> URL {
		return URL(fileURLWithPath: try sh.sh("which \(bin)").trimmingCharacters(in: .newlines))
	}

    private static var vtool : URL {
		get throws {
			try binPath("vtool")
		}
    }

    private static var otool : URL {
		get throws {
			try binPath("otool")
		}
    }

    private static var install_name_tool : URL {
		get throws {
			try binPath("install_name_tool")
		}
    }

    private static var ldid : URL {
		get throws {
			try binPath("ldid")
		}
    }
    
//    private static func builtInUtil(_ name : String) -> URL{
//        let tools = Bundle.main.url(forResource: name, withExtension: "")!
//        sh.codesign(tools)
//        do {
//            try tools.setBinaryPosixPermissions(0x755)
//        } catch{
//            Log.shared.error(error)
//        }
//        return tools
//    }
}

extension URL {
    func setBinaryPosixPermissions(_ permissions: Int) throws {
        try FileManager.default.setAttributes([
            .posixPermissions: permissions
        ], ofItemAtPath: self.path)
    }
}
