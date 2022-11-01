//
//  InstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/9/22.
//

import SwiftUI

class InstallPreferences: NSObject, ObservableObject {
    static var shared = InstallPreferences()

    @objc @AppStorage("AlwaysInstallPlayTools") var alwaysInstallPlayTools = true

    @AppStorage("ShowInstallPopup") var showInstallPopup = false
}

struct InstallSettings: View {
    public static var shared = InstallSettings()

    @ObservedObject var installPreferences = InstallPreferences.shared

    var body: some View {
        Form {
            Toggle("preferences.toggle.showInstallPopup", isOn: $installPreferences.showInstallPopup)
            GroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Toggle("preferences.toggle.alwaysInstallPlayTools",
                               isOn: $installPreferences.alwaysInstallPlayTools)
                    }
                    Spacer()
                }
            }.disabled(installPreferences.showInstallPopup)
            Spacer()
        }
        .padding(20)
        .frame(width: 350, height: 100, alignment: .center)
    }
}
