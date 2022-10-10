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
    @EnvironmentObject var storeVM: StoreVM

    private enum Tabs: Hashable {
        case updates, ipasource, installsettings
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
                .environmentObject(storeVM)
            InstallSettings.shared
                .tabItem {
                    Label("Install", systemImage: "arrow.down.app")
                }
                .tag(Tabs.installsettings)
        }
    }
}
