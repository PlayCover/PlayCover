//
//  UninstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 9/26/22.
//

import SwiftUI

@Observable
final class UninstallPreferences {
    static var shared: UninstallPreferences { AppEnvironment.shared.uninstallPreferences }

    /// The per-uninstall cleanup options, in the order the confirmation dialog lists them.
    static let cleanupOptions: [(keyPath: ReferenceWritableKeyPath<UninstallPreferences, Bool>, title: String)] = [
        (\.clearAppData, "preferences.toggle.clearAppData"),
        (\.removeAppKeymap, "preferences.toggle.removeKeymap"),
        (\.removeAppSettings, "preferences.toggle.removeSetting"),
        (\.removeAppEntitlements, "preferences.toggle.removeEntitlements"),
        (\.removePlayChain, "preferences.toggle.removePlayChain")
    ]

    private enum Keys {
        static let clearAppData = "ClearAppDataUninstall"
        static let removeAppKeymap = "RemoveAppKeymapUninstall"
        static let removeAppSettings = "RemoveAppSettingUninstall"
        static let removeAppEntitlements = "RemoveAppEntitlementsUninstall"
        static let removePlayChain = "RemovePlayChainUninstall"
        static let showUninstallPopup = "ShowUninstallPopup"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var clearAppData: Bool { didSet { defaults.set(clearAppData, forKey: Keys.clearAppData) } }
    var removeAppKeymap: Bool { didSet { defaults.set(removeAppKeymap, forKey: Keys.removeAppKeymap) } }
    var removeAppSettings: Bool { didSet { defaults.set(removeAppSettings, forKey: Keys.removeAppSettings) } }
    var removeAppEntitlements: Bool {
        didSet { defaults.set(removeAppEntitlements, forKey: Keys.removeAppEntitlements) }
    }
    var removePlayChain: Bool { didSet { defaults.set(removePlayChain, forKey: Keys.removePlayChain) } }
    var showUninstallPopup: Bool { didSet { defaults.set(showUninstallPopup, forKey: Keys.showUninstallPopup) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Keys.showUninstallPopup: true])
        clearAppData = defaults.bool(forKey: Keys.clearAppData)
        removeAppKeymap = defaults.bool(forKey: Keys.removeAppKeymap)
        removeAppSettings = defaults.bool(forKey: Keys.removeAppSettings)
        removeAppEntitlements = defaults.bool(forKey: Keys.removeAppEntitlements)
        removePlayChain = defaults.bool(forKey: Keys.removePlayChain)
        showUninstallPopup = defaults.bool(forKey: Keys.showUninstallPopup)
    }
}

struct UninstallSettings: View {
    @Environment(UninstallPreferences.self) private var uninstallPreferences

    @State private var showPruneFileAlert = false

    var body: some View {
        @Bindable var uninstallPreferences = uninstallPreferences
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
        .frame(width: 600, height: 240, alignment: .center)
    }
}
