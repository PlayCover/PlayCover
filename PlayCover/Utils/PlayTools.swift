//
//  PlayTools.swift
//  PlayCover
//

import Foundation
import injection

// This has so many functionality in it that 250 lines is darn near impossible
// swiftlint:disable:next type_body_length
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

    static func installInIPA(_ exec: URL) async throws {
        var binary = try Data(contentsOf: exec)
        try Macho.stripBinary(&binary)

        Inject.injectMachO(machoPath: exec.path,
                           cmdType: .loadDylib,
                           backup: false,
                           injectPath: playToolsPath.path,
                           finishHandle: { result in
            if result {
                do {
                    let payload = exec.deletingLastPathComponent()
                    try installPluginInIPA(payload)

                    let info = AppInfo(contentsOf: payload.appendingPathComponent("Info")
                                                          .appendingPathExtension("plist"))
                    try syncUserDylibs(bundleIdentifier: info.bundleIdentifier, into: exec)

                    try Shell.signApp(exec)
                } catch {
                    Log.shared.error(error)
                }
            }
        })
    }

    static func installPluginInIPA(_ payload: URL) throws {
        let allFiles = try FileManager.default.contentsOfDirectory(
            at: bundledPlayToolsFramework, includingPropertiesForKeys: [])
        for localizationDirectory in allFiles where localizationDirectory.pathExtension == "lproj" {
            _ = try copyAsset(target: payload,
                              directoryName: localizationDirectory.lastPathComponent,
                              component: "Playtools", pathExtension: "strings")
        }

        let bundledPlayToolsResources = bundledPlayToolsFramework
            .appendingPathComponent("Versions")
            .appendingPathComponent("A")
            .appendingPathComponent("Resources")
        if FileManager.default.fileExists(atPath: bundledPlayToolsResources.path) {
            let allFiles = try FileManager.default.contentsOfDirectory(
                at: bundledPlayToolsResources, includingPropertiesForKeys: [])
            for localizationDirectory in allFiles where localizationDirectory.pathExtension == "lproj" {
                _ = try copyAsset(source: bundledPlayToolsResources,
                                  target: payload,
                                  directoryName: localizationDirectory.lastPathComponent,
                                  component: "Playtools", pathExtension: "strings")
            }
        }

        try installComponentBundles(into: payload)
    }

    static func installComponentBundles(into payload: URL) throws {
        let pluginsSource = bundledPlayToolsFramework.appendingPathComponent("PlugIns")
        let pluginsTarget = payload.appendingPathComponent("PlugIns")
        try FileManager.default.createDirectory(at: pluginsTarget, withIntermediateDirectories: true)

        let bundleNames = try FileManager.default.contentsOfDirectory(atPath: pluginsSource.path)
        let bundles = bundleNames
            .map { pluginsSource.appendingPathComponent($0) }
            .filter { $0.pathExtension == "bundle" }

        for bundleSource in bundles {
            let bundleTarget = pluginsTarget.appendingPathComponent(bundleSource.lastPathComponent)
            if FileManager.default.fileExists(atPath: bundleTarget.path) {
                try FileManager.default.removeItem(at: bundleTarget)
            }
            try FileManager.default.copyItem(at: bundleSource, to: bundleTarget)
            try bundleTarget.fixExecutable()
            try Shell.signMacho(bundleTarget)
        }
    }

    static func copyAsset(source: URL = bundledPlayToolsFramework, target: URL, directoryName: String,
                          component: String, pathExtension: String) throws -> URL {
        let directory = target.appendingPathComponent(directoryName)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let target = directory
                    .appendingPathComponent(component)
                    .appendingPathExtension(pathExtension)

        let source = source
                    .appendingPathComponent(directoryName)
                    .appendingPathComponent(component)
                    .appendingPathExtension(pathExtension)
        do {
            try FileManager.default.copyItem(at: source, to: target)
        } catch {
            try FileManager.default.removeItem(at: target)
            try FileManager.default.copyItem(at: source, to: target)
        }
        return target
    }

    static func injectInIPA(_ exec: URL, payload: URL) throws {
        var binary = try Data(contentsOf: exec)
        try Macho.stripBinary(&binary)

        Inject.injectMachO(machoPath: exec.path,
                           cmdType: .loadDylib,
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

                        let libraryTarget = payload.appendingPathComponent("Frameworks")
                            .appendingPathComponent("PlayTools")
                            .appendingPathExtension("dylib")

                        let tools = bundledPlayToolsFramework
                            .appendingPathComponent("PlayTools")

                        if FileManager.default.fileExists(atPath: libraryTarget.path) {
                            try FileManager.default.removeItem(at: libraryTarget)
                        }
                        try FileManager.default.copyItem(at: tools, to: libraryTarget)

                        try libraryTarget.fixExecutable()
                        try installPluginInIPA(payload)
                    } catch {
                        Log.shared.error(error)
                    }
                }
            }
        })
    }

    static func removeFromApp(_ exec: URL) async {
        Inject.removeMachO(machoPath: exec.path,
                           cmdType: .loadDylib,
                           backup: false,
                           injectPath: playToolsPath.path,
                           finishHandle: { result in
            if result {
                do {
                    let pluginsUrl = exec.deletingLastPathComponent()
                        .appendingPathComponent("PlugIns")

                    if FileManager.default.fileExists(atPath: pluginsUrl.path) {
                        try FileManager.default.removeItem(at: pluginsUrl)
                    }
                    try Shell.signApp(exec)
                } catch {
                    Log.shared.error(error)
                }
            }
        })
    }

    static func installedInExec(atURL url: URL) throws -> Bool {
        var binary = try Data(contentsOf: url)
        try Macho.stripBinary(&binary)
        var result = false
        try _ = Macho.iterateLoadCommands(binary: binary) { offset, shouldSwap in
            let loadCommand = binary.extract(load_command.self, offset: offset,
                                             swap: shouldSwap ? swap_load_command:nil)
            if loadCommand.cmd == UInt32(LC_LOAD_DYLIB) {
                let dylibCommand = binary.extract(dylib_command.self, offset: offset,
                                                  swap: shouldSwap ? swap_dylib_command:nil)

                let dylibName = String(data: binary,
                                       offset: offset,
                                       commandSize: Int(dylibCommand.cmdsize),
                                       loadCommandString: dylibCommand.dylib.name)
                if dylibName == playToolsPath.esc {
                    result = true
                    return true
                }
            }
            return false
        }
        return result
    }

    static func isInstalled() throws -> Bool {
        try FileManager.default.fileExists(atPath: playToolsPath.path)
            && FileManager.default.fileExists(atPath: akInterfacePath.path)
            && Macho.isMachoValidArch(playToolsPath)
    }

    // User plugins loading
    private static func userPluginsStore(bundleIdentifier: String) -> URL {
        playCoverContainer
            .appendingPathComponent("PlayTools")
            .appendingPathComponent("UserPlugins")
            .appendingPathComponent(bundleIdentifier)
    }

    static func userDylibs(bundleIdentifier: String) -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: userPluginsStore(bundleIdentifier: bundleIdentifier), includingPropertiesForKeys: nil) else {
            return []
        }
        return files.filter { $0.pathExtension == "dylib" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    static func addUserDylib(at sourceURL: URL, bundleIdentifier: String, appExecutable: URL) throws {
        let store = userPluginsStore(bundleIdentifier: bundleIdentifier)
        try FileManager.default.createDirectory(at: store, withIntermediateDirectories: true)

        let canonical = store.appendingPathComponent(sourceURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: canonical.path) {
            try FileManager.default.removeItem(at: canonical)
        }
        try FileManager.default.copyItem(at: sourceURL, to: canonical)

        do {
            // Validate & convert the plugin
            if try !Macho.isMachoValidArch(canonical) {
                try Macho.convertMacho(canonical)
            }
        } catch {
            try? FileManager.default.removeItem(at: canonical)
            throw PlayCoverError.invalidUserDylib
        }

        // Downloaded files carry a quarantine flag that blocks dlopen(); best-effort clear it.
        _ = try? Shell.run(print: false, "/usr/bin/xattr", "-d", "com.apple.quarantine", canonical.path)

        try syncUserDylibs(bundleIdentifier: bundleIdentifier, into: appExecutable)
    }

    static func removeUserDylib(named name: String, bundleIdentifier: String, appExecutable: URL) throws {
        let canonical = userPluginsStore(bundleIdentifier: bundleIdentifier).appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: canonical.path) {
            try FileManager.default.removeItem(at: canonical)
        }
        try syncUserDylibs(bundleIdentifier: bundleIdentifier, into: appExecutable)
    }

    // Resync
    static func syncUserDylibs(bundleIdentifier: String, into appExecutable: URL) throws {
        let targetDirectory = appExecutable.deletingLastPathComponent()
            .appendingPathComponent("Frameworks")
            .appendingPathComponent("UserPlugins")

        if FileManager.default.fileExists(atPath: targetDirectory.path) {
            try FileManager.default.removeItem(at: targetDirectory)
        }

        let dylibs = userDylibs(bundleIdentifier: bundleIdentifier)
        guard !dylibs.isEmpty else { return }

        try FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true)
        for source in dylibs {
            let target = targetDirectory.appendingPathComponent(source.lastPathComponent)
            try FileManager.default.copyItem(at: source, to: target)
            try target.fixExecutable()
            try Shell.signMacho(target)
        }
    }

	static func fetchEntitlements(_ exec: URL) throws -> String {
        do {
            return try Shell.run("/usr/bin/codesign", "-d", "--entitlements", "-", "--xml", exec.path)
        } catch {
            if error.localizedDescription.contains("Document is empty") {
                // Empty entitlements
                return ""
            } else if error.localizedDescription.contains("code object is not signed at all") {
                // IPA not signed
                return ""
            } else {
                throw error
            }
        }
	}
}
