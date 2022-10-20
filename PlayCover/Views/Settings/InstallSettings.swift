//
//  InstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/9/22.
//

import SwiftUI

struct InstallSettings: View {
    public static var shared = InstallSettings()

    @AppStorage("ShowInstallPlayToolsPopup") var showInstallPlayToolsPopup = true
    @AppStorage("AlwaysInstallPlayTools") var alwaysInstallPlayTools = true

    var body: some View {
        Form {
            Toggle("preferences.toggle.showInstallPopup", isOn: $showInstallPlayToolsPopup)
            Toggle("preferences.toggle.alwaysInstallPlayTools", isOn: $alwaysInstallPlayTools)
                .disabled(showInstallPlayToolsPopup)
        }
        .padding(20)
        .frame(width: 350, height: 100, alignment: .center)
    }
}
