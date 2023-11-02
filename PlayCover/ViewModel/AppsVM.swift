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
    @Published var searchText: String = ""
    @Published var updatingApps = true

    func fetchApps() {
        Task { @MainActor in
            updatingApps = true

            filteredApps.removeAll()
            apps.removeAll()

            do {
                let directoryContents = try FileManager.default
                    .contentsOfDirectory(at: PlayTools.playCoverContainer, includingPropertiesForKeys: nil, options: [])

                let subdirs = directoryContents.filter { $0.hasDirectoryPath }

                for sub in subdirs {
                    if sub.pathExtension.contains("app") &&
                        FileManager.default.fileExists(atPath: sub.appendingPathComponent("Info")
                                                                  .appendingPathExtension("plist")
                                                                  .path) {
                        let app = PlayApp(appUrl: sub)
                        print("Application installed under:", sub.path)

                        apps.append(app)
                        if searchText.isEmpty || app.searchText.contains(searchText.lowercased()) {
                            filteredApps.append(app)
                        }
                    }
                }

            } catch let error as NSError {
                print(error)
            }

            filteredApps.sort(by: { $0.name.lowercased() < $1.name.lowercased() })

            updatingApps = false
        }
    }
}
