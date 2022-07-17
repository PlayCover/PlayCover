//
//  SettingsView.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/16/22.
//

import SwiftUI
import Sparkle

struct PlayCoverSettingsView: View {
    @Binding var updater: UpdaterViewModel
    
    var body: some View {
        Form {
            Toggle("Check for updates on app launch", isOn: updater.$canCheckForUpdates)
            Toggle("Check for Pre-release updates", isOn: $prereleaseUpdates)
                .disabled(!updater.canCheckForUpdates)
                .onChange(of: updater.canCheckForUpdates, perform: { checkUpdates in
                    if !checkUpdates {
                        prereleaseUpdates = false
                    }
                })
        }
        .padding(20)
        .frame(width: 350, height: 100, alignment: .center)
    }
}

struct PlayCoverSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PlayCoverSettingsView(updater: UpdaterViewModel())
    }
}
