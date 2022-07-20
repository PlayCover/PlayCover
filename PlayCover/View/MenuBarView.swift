//
//  MenuBarView.swift
//  PlayCover
//

import SwiftUI

struct PlayCoverMenuView: Commands{
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
    var body: some Commands{
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

struct PlayCoverViewMenuView: Commands {
    @State private var isToggle : Bool = AppsVM.shared.showAppLinks
    
    var body: some Commands {
        CommandGroup(before: .sidebar)
        {
            ShowAppLinksCommand() // Can you already tell that I love Swift? /s
            Divider()
        }
    }
}

struct ShowAppLinksCommand: View{
    // Must be its own struct because SwiftUI does not update Command when ObservedState changes
    @ObservedObject var apps = AppsVM.shared
    
    var body: some View {
        Toggle(isOn: $apps.showAppLinks)
        {
            Text("Show app links")
        }.onChange(of: apps.showAppLinks){ value in
            UserDefaults.standard.set(value, forKey: "ShowLinks")
            apps.fetchApps()
        }
        .keyboardShortcut("A", modifiers: [.command, .option])
    }
}
