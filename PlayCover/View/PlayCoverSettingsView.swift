//
//  SettingsView.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/16/22.
//

import SwiftUI

struct PlayCoverSettingsView: View {
    @AppStorage("playcover.checkUpdates") private var checkUpdates = true
    @AppStorage("playcover.prereleaseUpdates") private var prereleaseUpdates = false
    
    var body: some View {
        Form {
            Toggle("Check for updates on app launch", isOn: $checkUpdates)
            Toggle("Check for Pre-release updates", isOn: $prereleaseUpdates)
                .disabled(!checkUpdates)
                .onChange(of: checkUpdates, perform: { checkUpdates in
                    if !checkUpdates {
                        prereleaseUpdates = false
                    }
                })
            Button("Check for updates now") {
                UpdateService.shared.checkUpdate(force: true)
            }
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
