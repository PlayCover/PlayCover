//
//  PlayTools.swift
//  PlayCover
//

import Foundation
import injection

// swiftlint:disable type_body_length

class PlayTools {
    private static let frameworksURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Frameworks")
    private static let playToolsFramework = frameworksURL
        .appendingPathComponent("PlayTools")
        .appendingPathExtension("framework")
    private static let playToolsPath = playToolsFramework
        .appendingPathComponent("PlayTools")
    private static let akInterfacePath = playToolsFramework
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
        Task(priority: .background) {
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
                FileManager.default.delete(at: URL(fileURLWithPath: playToolsFramework.path))

                // Install version of PlayTools bundled with PlayCover
                Log.shared.log("Copying PlayTools to Frameworks")
                if FileManager.default.fileExists(atPath: playToolsFramework.path) {
                    try FileManager.default.removeItem(at: playToolsFramework)
                }
                try FileManager.default.copyItem(at: bundledPlayToolsFramework, to: playToolsFramework)
            } catch {
                Log.shared.error(error)
            }
        }
    }

    static func stripBinary(_ exec: URL) {
        if Shell.shell("/usr/bin/lipo -archs \(exec.esc)")
            .rangeOfCharacter(from: .whitespacesAndNewlines) != nil {
            Shell.shell("/usr/bin/lipo \(exec.esc) -thin arm64 -output \(exec.esc)")
        }
    }

    static func replaceLibraries(atURL url: URL) throws {
        Log.shared.log("Replacing libswiftUIKit.dylib")
        try shell.shello(
            install_name_tool.path,
            "-change", "@rpath/libswiftUIKit.dylib", "/System/iOSSupport/usr/lib/swift/libswiftUIKit.dylib",
            url.path)
    }

    static func installInIPA(_ exec: URL) throws {
        stripBinary(exec)
        Inject.injectMachO(machoPath: exec.path,
                           cmdType: LC_Type.LOAD_DYLIB,
                           backup: false,
                           injectPath: playToolsPath.path,
                           finishHandle: { result in
            if result {
                do {
                    try installPluginInIPA(exec.deletingLastPathComponent())
                    shell.signApp(exec)
                } catch {
                    Log.shared.error(error)
                }
            }
        })
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
        stripBinary(exec)
        Inject.injectMachO(machoPath: exec.path,
                           cmdType: LC_Type.LOAD_DYLIB,
                           backup: false,
                           injectPath: "@executable_path/Frameworks/PlayTools.dylib",
                           finishHandle: { result in
            if result {
                Task(priority: .background) {
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
        })
    }

    static func removeFromApp(_ exec: URL) {
        Inject.removeMachO(machoPath: exec.path,
                           cmdType: LC_Type.LOAD_DYLIB,
                           backup: false,
                           injectPath: playToolsPath.path,
                           finishHandle: { result in
            if result {
                do {
                    let pluginUrl = exec.deletingLastPathComponent()
                        .appendingPathComponent("PlugIns")
                        .appendingPathComponent("AKInterface")
                        .appendingPathExtension("bundle")

                    if FileManager.default.fileExists(atPath: pluginUrl.path) {
                        try FileManager.default.removeItem(at: pluginUrl)
                    }

                    shell.signApp(exec)
                } catch {
                    Log.shared.error(error)
                }
            }
        })
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
        let binary = try Data(contentsOf: url)
        let header = binary.extract(mach_header_64.self)
        var offset = MemoryLayout.size(ofValue: header)

        for _ in 0..<header.ncmds {
            let loadCommand = binary.extract(load_command.self, offset: offset)
            switch loadCommand.cmd {
            case UInt32(LC_ENCRYPTION_INFO_64):
                let infoCommand = binary.extract(encryption_info_command_64.self, offset: offset)
                if infoCommand.cryptid != 0 {
                    return true
                }
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }

        return false
    }

    static func installedInExec(atURL url: URL) throws -> Bool {
        let binary = try Data(contentsOf: url)
        let header = binary.extract(mach_header_64.self)
        var offset = MemoryLayout.size(ofValue: header)

        for _ in 0..<header.ncmds {
            let loadCommand = binary.extract(load_command.self, offset: offset)
            switch loadCommand.cmd {
            case UInt32(LC_LOAD_DYLIB):
                let dylibCommand = binary.extract(dylib_command.self, offset: offset)
                let dylibName = String.init(data: binary,
                                            offset: offset,
                                            commandSize: Int(dylibCommand.cmdsize),
                                            loadCommandString: dylibCommand.dylib.name)
                if dylibName == playToolsPath.esc {
                    return true
                }
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
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
            return  try shell.sh("codesign --display --entitlements - --xml \(exec.path.esc)" +
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
        URL(fileURLWithPath: try shell.sh("which \(bin)", print: false).trimmingCharacters(in: .newlines))
    }

    private static var vtool: URL {
        get throws {
            try binPath("vtool")
        }
    }

    private static var install_name_tool: URL {
        get throws {
            try binPath("install_name_tool")
        }
    }
}

extension URL {
    func setBinaryPosixPermissions(_ permissions: Int) throws {
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: path)
    }
}

extension Data {
    func extract<T>(_ type: T.Type, offset: Int = 0) -> T {
        let data = self[offset..<offset + MemoryLayout<T>.size]
        return data.withUnsafeBytes { dataBytes in
            dataBytes.baseAddress!
                .assumingMemoryBound(to: UInt8.self)
                .withMemoryRebound(to: T.self, capacity: 1) { (pointer) -> T in
                return pointer.pointee
            }
        }
    }
}

extension String {
    init(data: Data, offset: Int, commandSize: Int, loadCommandString: lc_str) {
        let loadCommandStringOffset = Int(loadCommandString.offset)
        let stringOffset = offset + loadCommandStringOffset
        let length = commandSize - loadCommandStringOffset
        self = String(data: data[stringOffset..<(stringOffset + length)],
                      encoding: .utf8)!.trimmingCharacters(in: .controlCharacters)
    }
}
