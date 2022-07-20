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
    @AppStorage("SUEnableAutomaticChecks") var autoUpdate = false
    @AppStorage("nightlyUpdates") var nightlyUpdates = false
    
    var body: some View {
        Form {
            Toggle("Automatically check for updates", isOn: $autoUpdate)
            Toggle("Check for nightly updates", isOn: $nightlyUpdates)
        }
        .padding(20)
        .frame(width: 350, height: 100, alignment: .center)
        .onChange(of: autoUpdate) { value in
            updaterViewModel.automaticallyCheckForUpdates = value
        }
        .onChange(of: nightlyUpdates) { _ in
            updaterViewModel.toggleAllowedChannels()
        }
    }
}
