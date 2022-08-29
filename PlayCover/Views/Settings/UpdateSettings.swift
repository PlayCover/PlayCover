//
//  UpdateSettings.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/23/22.
//

import Sparkle
import SwiftUI

struct UpdateSettings: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel
    @AppStorage("SUEnableAutomaticChecks") var autoUpdate = false

    var body: some View {
        Form {
            Toggle("preferences.toggle.automaticUpdates", isOn: $autoUpdate)
            Button("preferences.button.checkForUpdates") {
                updaterViewModel.checkForUpdates()
            }
        }
        .padding(20)
        .frame(width: 350, height: 100, alignment: .center)
        .onChange(of: autoUpdate) { value in
            updaterViewModel.automaticallyCheckForUpdates = value
        }
    }
}
