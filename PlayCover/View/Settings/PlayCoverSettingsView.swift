//
//  SettingsView.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/16/22.
//

import SwiftUI
import Sparkle

struct PlayCoverSettingsView: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel

    private enum Tabs: Hashable {
        case updates
    }

    var body: some View {
        TabView {
            UpdateSettings(updaterViewModel: updaterViewModel)
                .tabItem {
                    Label("Updates", systemImage: "square.and.arrow.down")
                }
                .tag(Tabs.updates)
        }
    }
}
