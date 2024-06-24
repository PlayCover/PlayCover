//
//  InstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/9/22.
//

import SwiftUI
import Cocoa
class InstallPreferences: NSObject, ObservableObject {
    static var shared = InstallPreferences()

    @objc @AppStorage("AlwaysInstallPlayTools") var alwaysInstallPlayTools = true

    @AppStorage("DefaultAppType") var defaultAppType: LSApplicationCategoryType = .none

    @AppStorage("ShowInstallPopup") var showInstallPopup = false
}

struct InstallSettings: View {
    public static var shared = InstallSettings()

    @ObservedObject var installPreferences = InstallPreferences.shared

    @State private var folderPath: String = "Nessuna cartella selezionata"

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
            Spacer()
                .frame(height: 20)
            GroupBox {
                VStack(alignment: .leading) {
                    Text("Cartella selezionata:")
                    Text(folderPath)
                        .padding(.bottom, 10)
                    Button(action: selectFolder) {
                        Text("Seleziona Cartella")
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }

    private func selectFolder() {
        let folderPicker = FolderPicker()
        folderPicker.pickFolder { url in
            if let url = url {
                folderPath = url.path
                print(folderPath)
                print(folderPath)
                print(folderPath)
                print(folderPath)
            } else {
                folderPath = "Nessuna cartella selezionata"
            }
        }
    }
}

class FolderPicker {
    func pickFolder(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.url)
            } else {
                completion(nil)
            }
        }
    }
}
