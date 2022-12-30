//
//  MenuBarView.swift
//  PlayCover
//

import AppKit
import SwiftUI
import DataCache

struct PlayCoverMenuView: Commands {
    @Binding var isSigningSetupShown: Bool
    var body: some Commands {
        CommandGroup(after: .systemServices) {
            Button("menubar.log.copy") {
                Log.shared.logdata.copyToClipBoard()
            }
            .keyboardShortcut("L", modifiers: [.command, .option])
            Button("menubar.configSigning") {
                isSigningSetupShown = true
            }
        }
    }
}

struct PlayCoverHelpMenuView: Commands {
    @ObservedObject var updaterViewModel: UpdaterViewModel

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updaterViewModel: updaterViewModel)
        }

        CommandGroup(replacing: .help) {
            Button("menubar.documentation") {
                if let url = URL(string: "https://docs.playcover.io") {
                    NSWorkspace.shared.open(url)
                }
            }
            Divider()
            Button("menubar.website") {
                if let url = URL(string: "https://playcover.io") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("menubar.github") {
                if let url = URL(string: "https://github.com/PlayCover/PlayCover/") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("menubar.discord") {
                if let url = URL(string: "https://discord.gg/PlayCover") {
                    NSWorkspace.shared.open(url)
                }
            }
            #if DEBUG
            Divider()
            Button("[DEBUG] Crash app") {
                fatalError("Crash was triggered")
            }
            #endif
        }
    }
}

struct PlayCoverViewMenuView: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .importExport) {
            Button("menubar.exportToSideloady") {
                if InstallVM.shared.installing {
                    Log.shared.error(PlayCoverError.waitInstallation)
                } else if DownloadVM.shared.downloading {
                    Log.shared.error(PlayCoverError.waitDownload)
                } else {
                    NSOpenPanel.selectIPA { result in
                        if case .success(let url) = result {
                            uif.ipaUrl = url
                            Installer.install(ipaUrl: url, export: true, returnCompletion: { ipa in
                                DispatchQueue.main.async {
                                    if let ipa = ipa {
                                        ipa.showInFinder()
                                        let config = NSWorkspace.OpenConfiguration()
                                        config.promptsUserIfNeeded = true
                                        let url = NSWorkspace.shared
                                            .urlForApplication(withBundleIdentifier: "com.sideloadly.sideloadly")
                                        if let sideloadlyUrl = url {
                                            NSWorkspace.shared
                                                .open([ipa], withApplicationAt: sideloadlyUrl, configuration: config)
                                        } else {
                                            Log.shared.error("Could not find Sideloadly!")
                                        }
                                    } else {
                                        Log.shared.error("Could not find file!")
                                    }
                                }
                            })
                        }
                    }
                }
            }
        }
        CommandGroup(before: .sidebar) {
            Button("menubar.clearCache") {
                DataCache.instance.cleanAll()
                URLCache.iconCache.removeAllCachedResponses()
                do {
                    if let oldCacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
                        if FileManager.default.fileExists(atPath: oldCacheFolder.path) {
                            try FileManager.default.removeItem(at: oldCacheFolder)
                        }
                    }
                } catch {
                    Log.shared.error(error)
                }
            }
            .keyboardShortcut("R", modifiers: [.command, .shift])
            Divider()
        }
    }
}
