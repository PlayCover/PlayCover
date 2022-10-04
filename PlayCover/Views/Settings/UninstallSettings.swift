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

    @AppStorage("ShowUninstallPopup") var showUninstallPopup = true

    @State private var showPruneFileAlert = false

    public func setSettings(_ title: String, _ state: Bool) {
        switch title {
        case NSLocalizedString("alert.uninstall.clearAppData", comment: ""):
            UninstallSettings.shared.clearAppDataUninstall = state
        case NSLocalizedString("alert.uninstall.removeKeymap", comment: ""):
            UninstallSettings.shared.removeAppKeymapUninstall = state
        case NSLocalizedString("alert.uninstall.removeSetting", comment: ""):
            UninstallSettings.shared.removeAppSettingUninstall = state
        case NSLocalizedString("alert.uninstall.removeEntitlements", comment: ""):
            UninstallSettings.shared.removeAppEntitlementsUninstall = state
        default:
            break
        }
    }

    public func getSettings(_ title: String) -> Bool? {
        switch title {
        case NSLocalizedString("alert.uninstall.clearAppData", comment: ""):
            return UninstallSettings.shared.clearAppDataUninstall
        case NSLocalizedString("alert.uninstall.removeKeymap", comment: ""):
            return UninstallSettings.shared.removeAppKeymapUninstall
        case NSLocalizedString("alert.uninstall.removeSetting", comment: ""):
            return UninstallSettings.shared.removeAppSettingUninstall
        case NSLocalizedString("alert.uninstall.removeEntitlements", comment: ""):
            return UninstallSettings.shared.removeAppEntitlementsUninstall
        default:
            return nil
        }
    }

    var body: some View {
        Form {
            Toggle("preferences.toggle.showUninstall", isOn: $showUninstallPopup)
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
