//
//  AppViewModel.swift
//  PlayCover
//

import Foundation
import Cocoa

class AppsVM: ObservableObject {

    static let shared = AppsVM()

    private init() {
        PlayTools.install()
        fetchApps()
        TempAllocator.clearTemp()
    }

    @Published var apps: [BaseApp] = []
    @Published var updatingApps: Bool = false
    @Published var showAppLinks = UserDefaults.standard.bool(forKey: "ShowLinks")

    func fetchApps() {
        DispatchQueue.global(qos: .background).async {
            var result: [BaseApp] = []
            do {

                let containers = try AppContainer.containers()
                let directoryContents = try FileManager.default
                    .contentsOfDirectory(at: PlayTools.playCoverContainer, includingPropertiesForKeys: nil, options: [])

                let subdirs = directoryContents.filter { $0.hasDirectoryPath }

                for sub in subdirs {
                    if sub.pathExtension.contains("app") &&
                        fileMgr.fileExists(atPath: sub.appendingPathComponent("Info.plist").path) {
                        let app = PlayApp(appUrl: sub)
                        if let container = containers[app.info.bundleIdentifier] {
                            app.container = container
                            print("Application installed under:", sub.path)
                        }
                        result.append(app)
                    }
                }

            } catch let error as NSError {
                print(error)
            }

            DispatchQueue.main.async {
                self.apps.removeAll()
                self.apps.append(PlayApp.add)

                if UserDefaults.standard.bool(forKey: "ShowLinks") {
                    for app in StoreApp.storeApps {
                        if !result.contains(where: { $0.id == app.id }) {
                            result.append(app)
                        }
                    }
                }

                if !uif.searchText.isEmpty {
                    result = result.filter({ $0.searchText.contains(uif.searchText.lowercased()) })
                }

                self.apps.append(contentsOf: result)
            }

        }

    }

}
