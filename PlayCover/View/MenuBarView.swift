//
//  MenuBarView.swift
//  PlayCover
//

import SwiftUI

struct PlayCoverMenuView: Commands{
    @Binding var showToast: Bool
    @Binding var updaterViewModel: UpdaterViewModel
    
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
    var body: some Commands{
        CommandGroup(after: .appInfo) {
            CheckForUpdatesView(updaterViewModel: updaterViewModel)
        }

        CommandGroup(replacing: .help) {
            Button("Documentation") {
                NSWorkspace.shared.open(URL(string:"https://github.com/PlayCover/PlayCover/wiki")!)
            }
            Divider()
            Button("Website") {
                NSWorkspace.shared.open(URL(string: "https://playcover.io")!)
            }
            Button("GitHub") {
                NSWorkspace.shared.open(URL(string:"https://github.com/PlayCover/PlayCover/")!)
            }
            Button("Discord") {
                NSWorkspace.shared.open(URL(string: "https://discord.gg/PlayCover")!)
            }
        }
    }
}
