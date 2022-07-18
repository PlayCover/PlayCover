//
//  SettingsView.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/16/22.
//

import SwiftUI
import Sparkle

struct PlayCoverSettingsView: View {
    @AppStorage("SUEnableAutomaticChecks") var autoUpdate = false
    @AppStorage("betaUpdates") var betaUpdates = false
    
    var body: some View {
        Form {
            Toggle("Automatically check for updates", isOn: $autoUpdate)
            Toggle("Check for beta updates", isOn: $betaUpdates)
                .disabled(!autoUpdate)
                .onChange(of: autoUpdate, perform: { autoUpdate in
                    if !autoUpdate {
                        betaUpdates = false
                    }
                })
        }
        .padding(20)
        .frame(width: 350, height: 100, alignment: .center)
    }
}

struct PlayCoverSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PlayCoverSettingsView()
    }
}
