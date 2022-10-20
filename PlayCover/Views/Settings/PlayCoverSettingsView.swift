//
//  SettingsView.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/16/22.
//

import Sparkle
import SwiftUI

struct PlayCoverSettingsView: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel
    @EnvironmentObject var ipaSourceVM: IPASourceVM

    private enum Tabs: Hashable {
        case updates, ipasource, uninstall
    }

    var body: some View {
        TabView {
            UpdateSettings(updaterViewModel: updaterViewModel)
                .tabItem {
                    Label("preferences.tab.updates", systemImage: "square.and.arrow.down")
                }
                .tag(Tabs.updates)
            UninstallSettings.shared
                .tabItem {
                  Label("preferences.tab.uninstall", systemImage: "trash.square")
                }
                .tag(Tabs.uninstall)
            IPASourceSettings()
                .tabItem {
                    Label("preferences.tab.ipasource", systemImage: "list.bullet")
                }
                .tag(Tabs.ipasource)
                .environmentObject(ipaSourceVM)
        }
    }
}
