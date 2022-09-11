//
//  MenuBarView.swift
//  PlayCover
//

import AppKit
import SwiftUI

struct PlayCoverMenuView: Commands {
    @Binding var isSigningSetupShown: Bool
    var body: some Commands {
        CommandGroup(after: .systemServices) {
            Button("menubar.log.copy") {
                Log.shared.logdata.copyToClipBoard()
            }
            .keyboardShortcut("L", modifiers: [.command, .option])
            Button("Configure Signing") {
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
                NSWorkspace.shared.open(URL(string: "https://docs.playcover.io")!)
            }
            Divider()
            Button("menubar.website") {
                NSWorkspace.shared.open(URL(string: "https://playcover.io")!)
            }
            Button("menubar.github") {
                NSWorkspace.shared.open(URL(string: "https://github.com/PlayCover/PlayCover/")!)
            }
            Button("menubar.discord") {
                NSWorkspace.shared.open(URL(string: "https://discord.gg/PlayCover")!)
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
        CommandGroup(replacing: .importExport) {
            Button("menubar.exportToSideloady") {
                if InstallVM.shared.installing {
                    Log.shared.error(PlayCoverError.waitInstallation)
                } else {
                    NSOpenPanel.selectIPA { result in
                        if case .success(let url) = result {
                            uif.ipaUrl = url
                            Installer.exportForSideloadly(ipaUrl: uif.ipaUrl!, returnCompletion: { ipa in
                                DispatchQueue.main.async {
                                    if let ipa = ipa {
                                        ipa.showInFinder()
                                        let config = NSWorkspace.OpenConfiguration()
                                        config.promptsUserIfNeeded = true
                                        let url = NSWorkspace.shared
                                            .urlForApplication(withBundleIdentifier: "com.sideloadly.sideloadly")
                                        if url != nil {
                                            let unwrap = url.unsafelyUnwrapped
                                            NSWorkspace.shared
                                                .open([ipa], withApplicationAt: unwrap, configuration: config)
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
    }
}
