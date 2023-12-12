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

    @AppStorage("DefaultAppType") var defaultAppType: LSApplicationCategoryType = .none

    @AppStorage("ShowInstallPopup") var showInstallPopup = false
}

struct InstallSettings: View {
    public static var shared = InstallSettings()

    @ObservedObject var installPreferences = InstallPreferences.shared

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("settings.applicationCategoryType")
                Spacer()
                Picker("", selection: installPreferences.$defaultAppType) {
                    ForEach(LSApplicationCategoryType.allCases, id: \.rawValue) { value in
                        Text(value.localizedName)
                            .tag(value)
                    }
                }
                .frame(width: 225)
            }
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
        .frame(width: 400, height: 200)
    }
}
