//
//  MenuBarView.swift
//  PlayCover
//

import SwiftUI

struct PlayCoverMenuView: Commands {
    @Binding var showToast: Bool

    var body: some Commands {
        CommandGroup(after: .systemServices) {
            Button("Copy log") {
                Log.shared.logdata.copyToClipBoard()
                showToast.toggle()
            }
            .keyboardShortcut("L", modifiers: [.command, .option])
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
            Button("Documentation") {
                NSWorkspace.shared.open(URL(string: "https://github.com/PlayCover/PlayCover/wiki")!)
            }
            Divider()
            Button("Website") {
                NSWorkspace.shared.open(URL(string: "https://playcover.io")!)
            }
            Button("GitHub") {
                NSWorkspace.shared.open(URL(string: "https://github.com/PlayCover/PlayCover/")!)
            }
            Button("Discord") {
                NSWorkspace.shared.open(URL(string: "https://discord.gg/PlayCover")!)
            }
            Divider()
            Button("Download more apps") {
                NSWorkspace.shared.open(URL(string: "https://ipa.playcover.workers.dev/0:/")!)
            }
        }
    }
}

struct PlayCoverViewMenuView: Commands {
    var body: some Commands {
        CommandGroup(replacing: .importExport) {
            Button("Export to Sideloadly") {
                if InstallVM.shared.installing {
                    Log.shared.error(PlayCoverError.waitInstallation)
                } else {
                    NSOpenPanel.selectIPA { (result) in
                        if case let .success(url) = result {
                            uif.ipaUrl = url
                            Installer.exportForSideloadly(ipaUrl: uif.ipaUrl!, returnCompletion: { (ipa) in
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
        CommandGroup(before: .sidebar) {
            ShowAppLinksCommand()
            Divider()
        }
    }
}

struct ShowAppLinksCommand: View {
    @ObservedObject var apps = AppsVM.shared

    var body: some View {
        Toggle(isOn: $apps.showAppLinks) {
            Text("Show app links")
        }.onChange(of: apps.showAppLinks) { value in
            UserDefaults.standard.set(value, forKey: "ShowLinks")
            apps.fetchApps()
        }
        .keyboardShortcut("A", modifiers: [.command, .option])
    }
}
