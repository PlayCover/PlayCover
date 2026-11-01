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
