//
//  UninstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 9/26/22.
//

import SwiftUI

struct UninstallSettings: View {
    public static var shared = UninstallSettings()

    @AppStorage("ClearAppDataUninstall") var clearAppDataUninstall = false
    @AppStorage("RemoveAppKeymapUninstall") var removeAppKeymapUninstall = false
    @AppStorage("RemoveAppSettingUninstall") var removeAppSettingUninstall = false
    @AppStorage("RemoveAppEntitlementsUninstall") var removeAppEntitlementsUninstall = false

    @State private var showPruneFileAlert = false

    var body: some View {
        Form {
            Toggle("preferences.toggle.clearAppData", isOn: $clearAppDataUninstall)
            Toggle("preferences.toggle.removeKeymap", isOn: $removeAppKeymapUninstall)
            Toggle("preferences.toggle.removeSetting", isOn: $removeAppSettingUninstall)
            Toggle("preferences.toggle.removeEntitlements", isOn: $removeAppEntitlementsUninstall)
            Button("preferences.button.pruneFiles") {
                showPruneFileAlert.toggle()
            }
            .alert("preferences.prune.alert", isPresented: $showPruneFileAlert, actions: {
                Button("preferences.button.pruneFiles", role: .destructive) {
                    Uninstaller.pruneFiles()
                }
                Button("button.Cancel", role: .cancel) {
                    showPruneFileAlert.toggle()
                }
                .keyboardShortcut(.defaultAction)
            }, message: {
                Text("preferences.prune.message")
            })
        }
        .padding(30)
        .frame(width: 350, height: 150, alignment: .center)
    }
}
