//
//  SettingsView.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/16/22.
//

import Sparkle
import SwiftUI

struct PlayCoverSettingsView: View {
    var updaterViewModel: UpdaterViewModel

    private enum Tabs: Hashable {
        case updates, ipasource, keyCover, install, uninstall
    }

    var body: some View {
        TabView {
            UpdateSettings(updaterViewModel: updaterViewModel)
                .tabItem {
                    Label("preferences.tab.updates", systemImage: "square.and.arrow.down")
                }
                .tag(Tabs.updates)
            IPASourceSettings()
                .tabItem {
                    Label("preferences.tab.ipasource", systemImage: "list.bullet")
                }
                .tag(Tabs.ipasource)
            KeyCoverSettings()
                .tabItem {
                    Label("KeyCover", systemImage: "key.fill")
                }
                .tag(Tabs.keyCover)
            InstallSettings()
                .tabItem {
                    Label("preferences.tab.install", systemImage: "arrow.down.app")
                }
                .tag(Tabs.install)
            UninstallSettings()
                .tabItem {
                  Label("preferences.tab.uninstall", systemImage: "trash.square")
                }
                .tag(Tabs.uninstall)
        }
    }
}
