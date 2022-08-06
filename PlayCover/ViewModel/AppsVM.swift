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

    @Published var apps: [PlayApp] = []
    @Published var updatingApps: Bool = false
    @Published var showAppLinks = UserDefaults.standard.bool(forKey: "ShowLinks")

    func fetchApps() {
        DispatchQueue.global(qos: .userInteractive).async {
            var result: [PlayApp] = []
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

                if !uif.searchText.isEmpty {
                    result = result.filter({ $0.searchText.contains(uif.searchText.lowercased()) })
                }

                _ = Store.storeApps

                self.apps.append(contentsOf: result)
            }

        }

    }

}
