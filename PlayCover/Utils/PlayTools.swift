//
//  PlayTools.swift
//  PlayCover
//

import Foundation

class PlayTools {
    private static let frameworksURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Frameworks")
    private static let playToolsFramwework = frameworksURL
        .appendingPathComponent("PlayTools")
        .appendingPathExtension("framework")
    private static let playToolsPath = playToolsFramwework
        .appendingPathComponent("PlayTools")
    private static let akInterfacePath = playToolsFramwework
        .appendingPathComponent("PlugIns")
        .appendingPathComponent("AKInterface")
        .appendingPathExtension("bundle")
    private static let bundledPlayToolsFramework = Bundle.main.bundleURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Frameworks")
        .appendingPathComponent("PlayTools")
        .appendingPathExtension("framework")

    public static var playCoverContainer: URL {
        let playCoverPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("io.playcover.PlayCover")
        if !FileManager.default.fileExists(atPath: playCoverPath.path) {
            do {
                try FileManager.default.createDirectory(at: playCoverPath,
                                                        withIntermediateDirectories: true,
                                                        attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }

        return playCoverPath
    }

    static func installOnSystem() {
        DispatchQueue.global(qos: .background).async {
            do {
                Log.shared.log("Installing PlayTools")

                // Check if Frameworks folder exists, if not, create it
                if !FileManager.default.fileExists(atPath: frameworksURL.path) {
                    try FileManager.default.createDirectory(
                        atPath: frameworksURL.path,
                        withIntermediateDirectories: true,
                        attributes: [:])
                }

                // Check if a version of PlayTools is already installed, if so remove it
                if FileManager.default.fileExists(atPath: playToolsFramwework.path) {
                    try FileManager.default.delete(at: URL(fileURLWithPath: playToolsFramwework.path))
                }

                // Install version of PlayTools bundled with PlayCover
                Log.shared.log("Copying PlayTools to Frameworks")
                try shell.sh("cp -r \(bundledPlayToolsFramework.esc) \(playToolsFramwework.esc)")
            } catch {
                Log.shared.error(error)
            }
        }
    }

    static func replaceLibraries(atURL url: URL) throws {
        Log.shared.log("Replacing libswiftUIKit.dylib")
        try shell.shello(
            install_name_tool.path,
            "-change", "@rpath/libswiftUIKit.dylib", "/System/iOSSupport/usr/lib/swift/libswiftUIKit.dylib",
            url.path)
    }

    static func installInIPA(_ exec: URL, _ payload: URL, resign: Bool = false) throws {
        patch_binary_with_dylib(exec.path, playToolsPath.path)
        if resign {
            shell.signApp(exec)
        }
    }

    static func installPluginInIPA(_ payload: URL) throws {
        let pluginsURL = payload.appendingPathComponent("PlugIns")
        if !FileManager.default.fileExists(atPath: pluginsURL.path) {
            try FileManager.default.createDirectory(at: pluginsURL, withIntermediateDirectories: true)
        }

        let bundleTarget = pluginsURL
            .appendingPathComponent("AKInterface")
            .appendingPathExtension("bundle")

        let akInterface = bundledPlayToolsFramework.appendingPathComponent("PlugIns")
            .appendingPathComponent("AKInterface")
            .appendingPathExtension("bundle")

        if FileManager.default.fileExists(atPath: bundleTarget.path) {
            try FileManager.default.removeItem(at: bundleTarget)
        }
        try FileManager.default.copyItem(at: akInterface, to: bundleTarget)
        try bundleTarget.fixExecutable()
        Shell.codesign(bundleTarget)
    }

    static func injectInIPA(_ exec: URL, payload: URL) throws {
        patch_binary_with_dylib(exec.path, "@executable_path/Frameworks/PlayTools.dylib")
        DispatchQueue.global(qos: .background).async {
            do {
                if !FileManager.default.fileExists(atPath: payload.appendingPathComponent("Frameworks").path) {
                    try FileManager.default.createDirectory(
                        at: payload.appendingPathComponent("Frameworks"),
                        withIntermediateDirectories: true)
                }
                if !FileManager.default.fileExists(atPath: payload.appendingPathComponent("PlugIns").path) {
                    try FileManager.default.createDirectory(
                        at: payload.appendingPathComponent("PlugIns"),
                        withIntermediateDirectories: true)
                }

                let libraryTarget = payload.appendingPathComponent("Frameworks")
                    .appendingPathComponent("PlayTools")
                    .appendingPathExtension("dylib")
                let bundleTarget = payload.appendingPathComponent("PlugIns")
                    .appendingPathComponent("AKInterface")
                    .appendingPathExtension("bundle")

                let tools = bundledPlayToolsFramework
                    .appendingPathComponent("PlayTools")
                let akInterface = bundledPlayToolsFramework.appendingPathComponent("PlugIns")
                    .appendingPathComponent("AKInterface")
                    .appendingPathExtension("bundle")

                if FileManager.default.fileExists(atPath: libraryTarget.path) {
                    try FileManager.default.removeItem(at: libraryTarget)
                }
                try FileManager.default.copyItem(at: tools, to: libraryTarget)

                if FileManager.default.fileExists(atPath: bundleTarget.path) {
                    try FileManager.default.removeItem(at: bundleTarget)
                }
                try FileManager.default.copyItem(at: akInterface, to: bundleTarget)

                try libraryTarget.fixExecutable()
                try bundleTarget.fixExecutable()
                Shell.codesign(bundleTarget)
            } catch {
                Log.shared.error(error)
            }
        }
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

    static func isInstalled() throws -> Bool {
        try FileManager.default.fileExists(atPath: playToolsPath.path)
            && FileManager.default.fileExists(atPath: akInterfacePath.path)
            && isValidArch(playToolsPath.path)
    }

    static func isValidArch(_ path: String) throws -> Bool {
        guard let output = try? shell.shello(vtool.path, "-show-build", path) else {
            return false
        }
        return output.contains("MACCATALYST")
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
