//
//  PlayAppExtensions.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/2/23.
//

import Foundation

extension PlayApp {
    func loadDiscordIPC() {
        let appTmp = self.container.containerUrl.appendingPathComponent("Data")
            .appendingPathComponent("tmp")

        appTmp.enumerateContents(options: []) { url, type in
            if url.lastPathComponent.contains("discord-ipc-") && (type.isSymbolicLink ?? true) {
                FileManager.default.delete(at: url)
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
