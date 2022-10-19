//
//  IPASourceVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 18/10/2022.
//

import Foundation

class IPASourceVM: SourceVM {
    static let shared = IPASourceVM(PlayTools.playCoverContainer
        .appendingPathComponent("Sources")
        .appendingPathExtension("plist"))

    @Published var apps: [StoreAppData] = []
    @Published var filteredApps: [StoreAppData] = []

    func appendAppData(_ data: [StoreAppData]) {
        for element in data {
            if let index = apps.firstIndex(where: {$0.bundleID == element.bundleID}) {
                if apps[index].version < element.version {
                    apps[index] = element
                    continue
                }
            } else {
                apps.append(element)
            }
        }
        fetchApps()
    }

    func fetchApps() {
        var result = apps
        if !uif.searchText.isEmpty {
            result = result.filter({
                $0.name.lowercased().contains(uif.searchText.lowercased())
            })
        }
        filteredApps = result
    }

    override func resolveSources() {
        if !NetworkVM.isConnectedToNetwork() { return }

        for index in 0..<sources.count {
            sources[index].status = .checking
            DispatchQueue.global(qos: .userInteractive).async {
                guard let url = URL(string: self.sources[index].source) else {
                    DispatchQueue.main.async {
                        self.sources[index].status = .badurl
                    }
                    return
                }

                do {
                    let contents = try String(contentsOf: url)
                    let jsonData = contents.data(using: .utf8)!
                    do {
                        let decoder = JSONDecoder()
                        decoder.keyDecodingStrategy = .convertFromSnakeCase
                        let data: [StoreAppData] = try decoder.decode([StoreAppData].self, from: jsonData)
                        if data.count > 0 {
                            DispatchQueue.main.async {
                                self.sources[index].status = .valid
                                self.appendAppData(data)
                            }
                            return
                        }
                    } catch {
                        DispatchQueue.main.async {
                            self.sources[index].status = .badjson
                        }
                            return
                    }
                } catch {
                    DispatchQueue.main.async {
                        self.sources[index].status = .badurl
                    }
                    return
                }
            }
        }

        apps.removeAll()
        fetchApps()
    }
}

struct StoreAppData: Codable, Equatable {
    var bundleID: String
    let name: String
    let version: String
    let itunesLookup: String
    let link: String
}
