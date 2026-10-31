//
//  PlayAppExtensions.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/2/23.
//

import Foundation

extension PlayApp {
    func loadDiscordIPC() {
        if self.container.doesExist() {
            let appTmp = self.container.containerUrl.appendingPathComponent("Data")
                .appendingPathComponent("tmp")

            try? FileManager.default.createDirectory(at: appTmp, withIntermediateDirectories: false)

            appTmp.enumerateContents { url, _ in
                if url.lastPathComponent.range(of: "discord-ipc-[0-9]", options: .regularExpression) != nil {
                    do {
                        try FileManager.default.removeItem(at: url)
                    } catch {
                        print("failed to remove discord ipc: \(error)")
                    }
                }
            }

            guard self.settings.settings.discordActivity.enable else {
                return
            }

            let userTmp = FileManager.default.temporaryDirectory.path

            for ipcPort in 0..<10 {
                let socketPath = userTmp + "/discord-ipc-\(ipcPort)"
                if FileManager.default.fileExists(atPath: socketPath) {
                    do {
                        try FileManager.default.createSymbolicLink(atPath: appTmp
                            .appendingPathComponent("discord-ipc-\(ipcPort)").path,
                                                                   withDestinationPath: socketPath)
                        print("Successfully linked discordipc for \(self.info.bundleIdentifier)")
                        return
                    } catch {
                        print(error)
                        continue
                    }
                }
            }

            print("Unable to link discordipc for \(self.info.bundleIdentifier)")
        }
    }

    /// One symlink to the sealed .app.
    ///
    /// The old shortcut was a directory of symlinks plus a copied Info.plist. That is not
    /// a signed bundle. On macOS 27, NSWorkspace refuses to launch it when the copy is not
    /// the sealed Info.plist (NSCocoaErrorDomain 256 / OSStatus -54). Install signs the real
    /// bundle after the shortcut is first built, so the first PlayCover launch hits that
    /// refusal. Finder can still open the real bundle, and a later launch succeeds once the
    /// copy matches. A single symlink resolves to the sealed bundle, so it cannot drift.
    func createAlias() {
        do {
            try FileManager.default.createDirectory(at: PlayApp.aliasDirectory,
                                                    withIntermediateDirectories: true)
            // removeItem deletes a symlink or the legacy directory-alias, not the real app.
            try? FileManager.default.removeItem(at: aliasURL)
            try FileManager.default.createSymbolicLink(at: aliasURL, withDestinationURL: url)
        } catch {
            Log.shared.log(error.localizedDescription)
        }
    }

    /// The system reads these Info.plist keys before the process starts, so the graphics
    /// switch has to write them here. Turning the switch off restores the stashed originals.
    func applyFullScreenDeclaration() throws {
        let infoURL = url.appendingPathComponent("Info.plist")
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
        let wantsOverride = settings.settings.overrideFullScreen && settings.settings.resolution != 6

        var stored = settings.settings
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
        settings.settings = stored
        try Shell.signApp(executable)
    }

    /// Re-sign only when plugins, entitlements, or Info.plist no longer match the seal.
    /// After a re-sign, refuse to launch until `codesign --verify` passes. One retry covers
    /// a seal that was still being written.
    func sealIfNeeded() throws {
        let pluginsUpdated = hasPlayTools() && PlayTools.pluginsNeedUpdate(in: url)
        if pluginsUpdated {
            try PlayTools.installPluginInIPA(url)
        }

        let entitlementsStale = try !Entitlements.areEntitlementsValid(app: self)
        if entitlementsStale {
            sign()
        }

        let infoPlistStale = try !isInfoPlistSigned()
        if infoPlistStale {
            try Shell.signApp(executable)
        }

        guard pluginsUpdated || entitlementsStale || infoPlistStale else { return }

        if signatureVerifies() { return }
        try Shell.signApp(executable)
        if !signatureVerifies() {
            throw PlayCoverError.invalidSignature
        }
    }

    private func signatureVerifies() -> Bool {
        do {
            try Shell.run(print: false, "/usr/bin/codesign", "--verify", "--strict", url.path)
            return true
        } catch {
            return false
        }
    }

    func removeAlias() {
        do {
            try FileManager.default.removeItem(at: aliasURL)
        } catch let error as NSError where error.domain == NSCocoaErrorDomain
            && error.code == NSFileNoSuchFileError {
            return
        } catch {
            Log.shared.log(error.localizedDescription)
        }
    }
}

/// Resumes a continuation at most once. LaunchServices can answer late, after the timeout.
final class OnceResume {
    private let lock = NSLock()
    private var resumed = false

    func finish(_ continuation: CheckedContinuation<Void, Error>, with result: Result<Void, Error>) {
        lock.lock()
        if resumed {
            lock.unlock()
            return
        }
        resumed = true
        lock.unlock()
        continuation.resume(with: result)
    }
}
