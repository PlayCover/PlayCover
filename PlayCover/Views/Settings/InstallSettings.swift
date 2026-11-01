//
//  InstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/9/22.
//

import SwiftUI

@Observable
final class InstallPreferences {
    static var shared: InstallPreferences { AppEnvironment.shared.installPreferences }

    private enum Keys {
        static let alwaysInstallPlayTools = "AlwaysInstallPlayTools"
        static let defaultAppType = "DefaultAppType"
        static let showInstallPopup = "ShowInstallPopup"
        static let showAppStorePopup = "ShowAppStorePopup"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var alwaysInstallPlayTools: Bool {
        didSet { defaults.set(alwaysInstallPlayTools, forKey: Keys.alwaysInstallPlayTools) }
    }
    var defaultAppType: LSApplicationCategoryType {
        didSet { defaults.set(defaultAppType.rawValue, forKey: Keys.defaultAppType) }
    }
    var showInstallPopup: Bool {
        didSet { defaults.set(showInstallPopup, forKey: Keys.showInstallPopup) }
    }
    var showAppStorePopup: Bool {
        didSet { defaults.set(showAppStorePopup, forKey: Keys.showAppStorePopup) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.alwaysInstallPlayTools: true,
            Keys.showInstallPopup: false,
            Keys.showAppStorePopup: true
        ])
        alwaysInstallPlayTools = defaults.bool(forKey: Keys.alwaysInstallPlayTools)
        defaultAppType = defaults.string(forKey: Keys.defaultAppType)
            .flatMap(LSApplicationCategoryType.init) ?? .none
        showInstallPopup = defaults.bool(forKey: Keys.showInstallPopup)
        showAppStorePopup = defaults.bool(forKey: Keys.showAppStorePopup)
    }
}

struct InstallSettings: View {
    @Environment(InstallPreferences.self) private var installPreferences

    var body: some View {
        @Bindable var installPreferences = installPreferences
        VStack(alignment: .leading) {
            HStack {
                Text("settings.applicationCategoryType")
                Spacer()
                Picker("", selection: $installPreferences.defaultAppType) {
                    ForEach(LSApplicationCategoryType.allCases, id: \.rawValue) { value in
                        Text(value.localizedName)
                            .tag(value)
                    }
                }
                .frame(width: 225)
            }
            Spacer()
                .frame(height: 20)
            Toggle("preferences.toggle.showAppStorePopup", isOn: $installPreferences.showAppStorePopup)
            Spacer()
                .frame(height: 20)
            Toggle("preferences.toggle.showInstallPopup", isOn: $installPreferences.showInstallPopup)
            GroupBox {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Toggle("preferences.toggle.alwaysInstallPlayTools",
                                   isOn: $installPreferences.alwaysInstallPlayTools)
                        }
                        Spacer()
                    }
                    Spacer()
                        .frame(height: 20)
                }
            }.disabled(installPreferences.showInstallPopup)
        }
        .padding(20)
        .frame(width: 600, height: 200)
    }
}
