//
//  AppSigner.swift
//  PlayCover
//

import Foundation

/// Everything that rewrites an installed app's bundle and has to re-seal it afterwards.
///
/// The decisions (which entitlements, which Info.plist keys) read app settings on the main actor; the
/// `codesign` runs themselves go through `Shell`'s `@concurrent` overloads, so the UI never blocks.
enum AppSigner {
    /// Signs with the entitlements composed from the app's settings and sandbox rules.
    static func sign(_ app: PlayApp) async {
        do {
            let tmpEnts = FileManager.default.temporaryDirectory
                .appendingEscapedPathComponent(ProcessInfo().globallyUniqueString)
                .appendingPathExtension("plist")
            let conf = try await Entitlements.composeEntitlements(app)
            try conf.store(tmpEnts)
            defer { try? FileManager.default.removeItem(at: tmpEnts) }
            try await Shell.signAppWith(app.executable, entitlements: tmpEnts)
        } catch {
            Log.shared.error(error)
        }
    }

    /// Re-sign only when plugins, entitlements, or Info.plist no longer match the seal.
    /// After a re-sign, refuse to launch until `codesign --verify` passes. One retry covers
    /// a seal that was still being written.
    static func sealIfNeeded(_ app: PlayApp) async throws {
        let pluginsUpdated = app.hasPlayTools() && PlayTools.pluginsNeedUpdate(in: app.url)
        if pluginsUpdated {
            try PlayTools.installPluginInIPA(app.url)
        }

        let entitlementsStale = try await !Entitlements.areEntitlementsValid(app: app)
        if entitlementsStale {
            await sign(app)
        }

        let infoPlistStale = try await !isInfoPlistSigned(app)
        if infoPlistStale {
            try await Shell.signApp(app.executable)
        }

        guard pluginsUpdated || entitlementsStale || infoPlistStale else { return }

        if await Shell.verifySignature(app.url) { return }
        try await Shell.signApp(app.executable)
        if await !Shell.verifySignature(app.url) {
            throw PlayCoverError.invalidSignature
        }
    }

    static func isInfoPlistSigned(_ app: PlayApp) async throws -> Bool {
        try await Shell.run("/usr/bin/codesign", "-dv", app.executable.path).contains("Info.plist entries")
    }

    /// The system reads these Info.plist keys before the process starts, so the graphics
    /// switch has to write them here. Turning the switch off restores the stashed originals.
    static func applyFullScreenDeclaration(_ app: PlayApp) async throws {
        let infoURL = app.url.appendingPathComponent("Info.plist")
        let data = try Data(contentsOf: infoURL)
        var format = PropertyListSerialization.PropertyListFormat.xml
        guard var info = try PropertyListSerialization.propertyList(
            from: data, options: .mutableContainersAndLeaves, format: &format) as? [String: Any]
        else { return }

        let forcedOrientations = [
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight"
        ]
        let currentOrientations = info["UISupportedInterfaceOrientations~ipad"] as? [String]
        let currentFullScreen = info["UIRequiresFullScreen"] as? Bool
        let alreadyForced = currentFullScreen == true && currentOrientations == forcedOrientations
        let wantsOverride = app.settings.settings.overrideFullScreen && app.settings.settings.resolution != 6

        var stored = app.settings.settings
        var changed = false

        if wantsOverride {
            if !alreadyForced {
                stored.fullScreenOverrideStashed = true
                stored.stashedRequiresFullScreen = currentFullScreen
                stored.stashedIpadOrientations = currentOrientations
                info["UIRequiresFullScreen"] = true
                info["UISupportedInterfaceOrientations~ipad"] = forcedOrientations
                changed = true
            }
        } else if stored.fullScreenOverrideStashed {
            if let fullscreen = stored.stashedRequiresFullScreen {
                info["UIRequiresFullScreen"] = fullscreen
            } else {
                info.removeValue(forKey: "UIRequiresFullScreen")
            }
            if let orientations = stored.stashedIpadOrientations {
                info["UISupportedInterfaceOrientations~ipad"] = orientations
            }
            stored.fullScreenOverrideStashed = false
            stored.stashedRequiresFullScreen = nil
            stored.stashedIpadOrientations = nil
            changed = true
        }

        guard changed else { return }
        let written = try PropertyListSerialization.data(fromPropertyList: info, format: format, options: 0)
        try written.write(to: infoURL, options: .atomic)
        app.settings.settings = stored
        try await Shell.signApp(app.executable)
    }

    /// Adds or removes `path` from the app's `DYLD_LIBRARY_PATH` and re-signs. Returns whether the
    /// path is present afterwards.
    static func setDyldLibraryPath(_ app: PlayApp, enabled: Bool? = nil, path: String) async -> Bool {
        app.info.lsEnvironment["DYLD_LIBRARY_PATH"] = app.info.lsEnvironment["DYLD_LIBRARY_PATH"] ?? ""

        if let enabled {
            if enabled {
                app.info.lsEnvironment["DYLD_LIBRARY_PATH"]? += "\(path):"
            } else {
                app.info.lsEnvironment["DYLD_LIBRARY_PATH"] = app.info.lsEnvironment["DYLD_LIBRARY_PATH"]?
                    .replacingOccurrences(of: "\(path):", with: "")
            }

            do {
                try await Shell.signApp(app.executable)
            } catch {
                Log.shared.error(error)
            }
        }

        return app.info.lsEnvironment["DYLD_LIBRARY_PATH"]?.contains(path) ?? false
    }

    /// Re-signs after a change that only touched Info.plist (e.g. the app category).
    static func reseal(_ app: PlayApp) async {
        do {
            try await Shell.signApp(app.executable)
        } catch {
            Log.shared.error(error)
        }
    }
}
