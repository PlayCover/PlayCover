//
//  AppViewModel.swift
//  PlayCover
//

import Foundation

class AppsVM: ObservableObject {

    static let shared = AppsVM()

    private init() {
        PlayTools.installOnSystem()
        fetchApps()
    }

    @Published var filteredApps: [PlayApp] = []
    @Published var apps: [PlayApp] = []

    @Published var updatingApps = true

    func fetchApps() {
        Task { @MainActor in
            updatingApps = true
            var result: [PlayApp] = []
            do {
                let containers = try AppContainer.containers()
                let directoryContents = try FileManager.default
                    .contentsOfDirectory(at: PlayTools.playCoverContainer, includingPropertiesForKeys: nil, options: [])

                let subdirs = directoryContents.filter { $0.hasDirectoryPath }

                for sub in subdirs {
                    if sub.pathExtension.contains("app") &&
                        FileManager.default.fileExists(atPath: sub.appendingPathComponent("Info")
                                                                  .appendingPathExtension("plist")
                                                                  .path) {
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

            apps = result

            updateApps(result)
        }
    }

    @MainActor func updateApps(_ newApps: [PlayApp]) {
        updatingApps = true
        self.filteredApps.removeAll()
        var filteredApps = newApps

        if !uif.searchText.isEmpty {
            filteredApps = newApps.filter({ $0.searchText.contains(uif.searchText.lowercased()) })
        }

        self.filteredApps.append(contentsOf: filteredApps)
        updatingApps = false
    }
}
