//
//  UninstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 9/26/22.
//

import SwiftUI

class UninstallPreferences: NSObject, ObservableObject {
    static var shared = UninstallPreferences()

    @objc @AppStorage("ClearAppDataUninstall") var clearAppData = false
    @objc @AppStorage("RemoveAppKeymapUninstall") var removeAppKeymap = false
    @objc @AppStorage("RemoveAppSettingUninstall") var removeAppSettings = false
    @objc @AppStorage("RemoveAppEntitlementsUninstall") var removeAppEntitlements = false
    @objc @AppStorage("RemovePlayChainUninstall") var removePlayChain = false

    @AppStorage("ShowUninstallPopup") var showUninstallPopup = true
}

struct UninstallSettings: View {
    public static var shared = UninstallSettings()

    @ObservedObject var uninstallPreferences = UninstallPreferences.shared

    @State private var showPruneFileAlert = false

    var body: some View {
        Form {
            Text("preferences.whenUninstalling")
            GroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Toggle("preferences.toggle.showUninstall",
                               isOn: $uninstallPreferences.showUninstallPopup)
                        Toggle("preferences.toggle.clearAppData",
                               isOn: $uninstallPreferences.clearAppData)
                        Toggle("preferences.toggle.removeKeymap",
                               isOn: $uninstallPreferences.removeAppKeymap)
                        Toggle("preferences.toggle.removeSetting",
                               isOn: $uninstallPreferences.removeAppSettings)
                        Toggle("preferences.toggle.removeEntitlements",
                               isOn: $uninstallPreferences.removeAppEntitlements)
                        Toggle("preferences.toggle.removePlayChain",
                               isOn: $uninstallPreferences.removePlayChain)
                    }
                    Spacer()
                }
            }
            Spacer()
                .frame(height: 20)
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
        .frame(width: 400, height: 240, alignment: .center)
    }
}
