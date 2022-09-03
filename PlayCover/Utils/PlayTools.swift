//
//  PlayTools.swift
//  PlayCover
//

import Foundation

class PlayTools {
    static func replaceLibraries(atURL url: URL) throws {
        Log.shared.log("Replacing libswiftUIKit.dylib")
        try shell.shello(
            install_name_tool.path,
            "-change", "@rpath/libswiftUIKit.dylib", "/System/iOSSupport/usr/lib/swift/libswiftUIKit.dylib",
            url.path)
    }

    static func installFor(_ exec: URL, resign: Bool = false) throws {
        patch_binary_with_dylib(exec.path, PLAY_TOOLS_PATH)
        if resign {
            shell.signApp(exec)
        }
    }

    static func injectFor(_ exec: URL, payload: URL) throws {
        patch_binary_with_dylib(exec.path, "@executable_path/Frameworks/PlayTools.dylib")
        try injectPlayTools(payload)
    }

    static func deleteFrom(_ exec: URL) throws {
        remove_play_tools_from(exec.path, PLAY_TOOLS_PATH)
        shell.signApp(exec)
    }

    static func convertMacho(_ macho: URL) throws {
        Log.shared.log("Converting \(macho.lastPathComponent) binary")
        try shell.shello(
            vtool.path,
            "-set-build-version", "maccatalyst", "11.0", "14.0",
            "-replace", "-output",
            macho.path, macho.path)
    }

    static func isMachoEncrypted(atURL url: URL) throws -> Bool {
        // Split output into blocks
        let otoolOutput = try shell.shello(otool.path, "-l", url.path).components(separatedBy: "Load command")
        // Check specifically for encryption info on the 64 bit block
        for block in otoolOutput where (block.contains("LC_ENCRYPTION_INFO_64") && block.contains("cryptid 1")) {
            return true
        }
        return false
    }

    static func install() {
        DispatchQueue.global(qos: .background).async {
            do {
                let tools = URL(fileURLWithPath: BUNDLED_PLAY_TOOLS_FRAMEWORKS_PATH)
                Log.shared.log("Installing PlayTools")
//                try convertMacho(tools)
//                sh.codesign(tools)
                if !fileMgr.fileExists(atPath: FRAMEWORKS_PATH) {
                    try fileMgr.createDirectory(
                        atPath: FRAMEWORKS_PATH,
                        withIntermediateDirectories: true,
                        attributes: [:])
                }
                if fileMgr.fileExists(atPath: PLAY_TOOLS_FRAMEWORKS_PATH) {
                    try fileMgr.delete(at: URL(fileURLWithPath: PLAY_TOOLS_FRAMEWORKS_PATH))
                }
                Log.shared.log("Copying PlayTools to Frameworks")
                try shell.sh("cp -r \(tools.esc) \(PLAY_TOOLS_FRAMEWORKS_PATH)")
            } catch {
                Log.shared.error(error)
            }
        }
    }

    static func injectPlayTools(_ payload: URL) throws {
        DispatchQueue.global(qos: .background).async {
            do {
                let tools = URL(fileURLWithPath: "\(BUNDLED_PLAY_TOOLS_FRAMEWORKS_PATH)/PlayTools")
                if !FileManager.default.fileExists(atPath: payload.appendingPathComponent("Frameworks").path) {
                    try FileManager.default.createDirectory(
                        at: payload.appendingPathComponent("Frameworks"),
                        withIntermediateDirectories: true)
                }
                let libraryTraget = payload.appendingPathComponent("Frameworks")
                    .appendingPathComponent("PlayTools")
                    .appendingPathExtension("dylib")
                shell.shell("cp \(tools.esc) \(libraryTraget.esc)")
                try libraryTraget.fixExecutable()
            } catch {
                Log.shared.error(error)
            }
        }
    }

    static func isInstalled() throws -> Bool {
        try fileMgr.fileExists(atPath: PLAY_TOOLS_PATH) && isValidArch(PLAY_TOOLS_PATH)
    }

    static func isValidArch(_ path: String) throws -> Bool {
        guard let output = try? shell.shello(vtool.path, "-show-build", path) else {
            return false
        }
        return output.contains("MACCATALYST")
    }

    private static let PLAY_TOOLS_FRAMEWORKS_PATH = "\(FRAMEWORKS_PATH)/PlayTools.framework"
    private static let PLAY_TOOLS_PATH = "\(PLAY_TOOLS_FRAMEWORKS_PATH)/PlayTools"
//    private static let PLAY_TOOLS_PATH = "\(FRAMEWORKS_PATH)/\(getSystemUUID()?.prefix(4) ?? "3DEF")N"
    private static let FRAMEWORKS_PATH = "/Users/\(NSUserName())/Library/Frameworks"
    private static let PLAY_COVER_PATH =
        URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover")
    private static let BUNDLED_PLAY_TOOLS_FRAMEWORKS_PATH =
        "\(Bundle.main.bundlePath)/Contents/Frameworks/PlayTools.framework"

    public static var playCoverContainer: URL {
        if !fileMgr.fileExists(atPath: PLAY_COVER_PATH.path) {
            do {
                try fileMgr.createDirectory(at: PLAY_COVER_PATH, withIntermediateDirectories: true, attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }

        return PLAY_COVER_PATH
    }

	static func fetchEntitlements(_ exec: URL) throws -> String {
        do {
            return  try shell.sh("codesign --display --entitlements - --xml '\(exec.path)'" +
                            " | xmllint --format -", pipeStdErr: false)
        } catch {
            if error.localizedDescription.contains("Document is empty") {
                // Empty entitlements
                return ""
            } else {
                throw error
            }
        }
	}

    private static func binPath(_ bin: String) throws -> URL {
        URL(fileURLWithPath: try shell.sh("which \(bin)").trimmingCharacters(in: .newlines))
    }

    private static var vtool: URL {
        get throws {
            try binPath("vtool")
        }
    }

    private static var otool: URL {
        get throws {
            try binPath("otool")
        }
    }

    private static var install_name_tool: URL {
        get throws {
            try binPath("install_name_tool")
        }
    }

    private static var ldid: URL {
        get throws {
            try binPath("ldid")
        }
    }
}

extension URL {
    func setBinaryPosixPermissions(_ permissions: Int) throws {
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: path)
    }
}
