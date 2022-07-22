//
//  MenuBarView.swift
//  PlayCover
//

import SwiftUI

struct PlayCoverMenuView: Commands {
    @Binding var showToast: Bool

    var body: some Commands {
        CommandGroup(after: .systemServices) {
            Button("menubar.log.copy") {
                Log.shared.logdata.copyToClipBoard()
                showToast.toggle()
            }
            .keyboardShortcut("L", modifiers: [.command, .option])
        }
    }
}

struct PlayCoverHelpMenuView: Commands {
    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("menubar.documentation") {
                NSWorkspace.shared.open(URL(string: "https://github.com/PlayCover/PlayCover/wiki")!)
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
        }
    }
}

struct PlayCoverViewMenuView: Commands {
    var body: some Commands {
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
            Text("menubar.showAppLinks")
        }.onChange(of: apps.showAppLinks) { value in
            UserDefaults.standard.set(value, forKey: "ShowLinks")
            apps.fetchApps()
        }
        .keyboardShortcut("A", modifiers: [.command, .option])
    }
}
