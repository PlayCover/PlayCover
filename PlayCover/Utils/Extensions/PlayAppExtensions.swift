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

            appTmp.enumerateContents { url, type in
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

    func createAlias() {
        do {
            try FileManager.default.createDirectory(atPath: aliasURL.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            url.enumerateContents(options: [.skipsSubdirectoryDescendants]) { ctxUrl, _ in
                try FileManager.default.createSymbolicLink(
                    at: self.aliasURL.appendingPathComponent(ctxUrl.lastPathComponent),
                    withDestinationURL: ctxUrl)
            }
        } catch {
            Log.shared.log(error.localizedDescription)
        }
    }

    func removeAlias() {
        FileManager.default.delete(at: aliasURL)
    }

    @MainActor
    func runMacOSWarning() async -> Bool {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("alert.error", comment: "")
        alert.informativeText = String(
         format: NSLocalizedString("macos.version", comment: "")
        )

        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("alert.start.anyway", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("alert.open.appstore", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))
        let result = alert.runModal()

        switch result {
        case .alertFirstButtonReturn:
            UserDefaults.standard.set(true, forKey: "\(info.bundleIdentifier).noMacAlert")
            return true

        case .alertSecondButtonReturn:
            let urlString = "https://itunes.apple.com/lookup?bundleId=\(info.bundleIdentifier)"
            let itunes: ITunesResponse? = await getITunesData(urlString)
            guard let appID = itunes?.results.first?.trackId else { return false }
            if let appLink: URL = URL(string: "itms-apps://apps.apple.com/app/id\(appID)") {
                NSWorkspace.shared.open(appLink)
            }
            return false

        default:
            return false
        }
    }

    var hasMacVersion: Bool {
        PlayApp.MACOS_APPS.contains(info.bundleIdentifier)
    }

    static let MACOS_APPS = [
        "com.innersloth.amongus",
        "com.devsisters.ck",
        "com.miHoYo.bh3global"
    ]

}
