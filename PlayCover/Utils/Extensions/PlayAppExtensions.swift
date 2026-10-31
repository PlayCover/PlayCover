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

    func createAlias() {
        do {
            try FileManager.default.createDirectory(atPath: aliasURL.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            url.enumerateContents(options: [.skipsSubdirectoryDescendants]) { ctxUrl, _ in
                let aliasItem = self.aliasURL.appendingPathComponent(ctxUrl.lastPathComponent)

                // LaunchServices on macOS 27 will not open the alias while Info.plist is a
                // symlink: it fails with -54 (permErr) and the user sees "does not have
                // permission to open (null)". A real copy is enough, and it stays current
                // because the alias is rebuilt on every PlayApp init and before every launch.
                if ctxUrl.lastPathComponent == "Info.plist" {
                    try FileManager.default.copyItem(at: ctxUrl, to: aliasItem)
                } else {
                    try FileManager.default.createSymbolicLink(at: aliasItem,
                                                               withDestinationURL: ctxUrl)
                }
            }
        } catch {
            Log.shared.log(error.localizedDescription)
        }
    }

    func removeAlias() {
        FileManager.default.delete(at: aliasURL)
    }
}
