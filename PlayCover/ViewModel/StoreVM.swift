//
//  Store.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 06/08/2022.
//

import Foundation

class StoreVM: ObservableObject, @unchecked Sendable {

    static let shared = StoreVM()

    private init() {
        sourcesUrl = PlayTools.playCoverContainer
            .appendingPathComponent("Sources")
            .appendingPathExtension("plist")
        sources = []
        if !decode() {
            encode()
        }
        resolveSources()
    }

    @Published var apps: [StoreAppData] = []
    @Published var searchText: String = ""
    @Published var filteredApps: [StoreAppData] = []
    @Published var sources: [SourceData] {
        didSet {
            encode()
        }
    }

    let sourcesUrl: URL

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: sourcesUrl)
            sources = try PropertyListDecoder().decode([SourceData].self, from: data)
            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(sources)
            try data.write(to: sourcesUrl)
            return true
        } catch {
            print(error)
            return false
        }
    }

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
        filteredApps.removeAll()
        filteredApps = apps
        if !searchText.isEmpty {
            filteredApps = filteredApps.filter({
                $0.name.lowercased().contains(searchText.lowercased())
            })
        }
    }

    func resolveSources() {
        guard NetworkVM.isConnectedToNetwork() else {
            return
        }

        apps.removeAll()
        for index in 0..<sources.endIndex {
            sources[index].status = .empty
            Task {
                if let url = URL(string: self.sources[index].source) {
                    URLSession.shared.dataTask(with: URLRequest(url: url)) { jsonData, response, error in
                        guard error == nil,
                              ((response as? HTTPURLResponse)?.statusCode ?? 200) == 200,
                              let jsonData = jsonData else {
                            Task { @MainActor in
                                self.sources[index].status = .badurl
                            }

                            return
                        }

                        do {
                            let data: [StoreAppData] = try JSONDecoder().decode([StoreAppData].self,
                                                                                from: jsonData)
                            if data.count > 0 {
                                Task { @MainActor in
                                    self.sources[index].status = self.sources[0..<index].filter({
                                        $0.source == self.sources[index].source && $0.id != self.sources[index].id
                                    }).isEmpty ? .valid : .duplicate

                                    self.appendAppData(data)
                                }
                            }
                        } catch {
                            Task { @MainActor in
                                self.sources[index].status = .badjson
                            }
                        }
                    }.resume()

                    Task { @MainActor in
                        self.sources[index].status = .checking
                    }

                    return
                }

                Task { @MainActor in
                    sources[index].status = .badurl
                }
            }
        }

        fetchApps()
    }

    func deleteSource(_ selected: inout Set<UUID>) {
        self.sources.removeAll(where: { selected.contains($0.id) })
        selected.removeAll()
        resolveSources()
    }

    func moveSourceUp(_ selected: inout Set<UUID>) {
        let selectedData = self.sources.filter({ selected.contains($0.id) })

        if let first = selectedData.first {
            if var index = self.sources.firstIndex(of: first) {
                index -= 1
                self.sources.removeAll(where: { selected.contains($0.id) })
                if index < 0 {
                    index = 0
                }
                self.sources.insert(contentsOf: selectedData, at: index)
            }
        }
    }

    func moveSourceDown(_ selected: inout Set<UUID>) {
        let selectedData = self.sources.filter({ selected.contains($0.id) })

        if let first = selectedData.first {
            if var index = self.sources.firstIndex(of: first) {
                index += 1
                self.sources.removeAll(where: { selected.contains($0.id) })
                if index > self.sources.endIndex {
                    index = self.sources.endIndex
                }
                self.sources.insert(contentsOf: selectedData, at: index)
            }
        }
    }

    func appendSourceData(_ data: SourceData) {
        self.sources.append(data)
        self.resolveSources()
    }
}

struct StoreAppData: Codable, Equatable {
    var bundleID: String
    let name: String
    let version: String
    let itunesLookup: String
    let link: String
    let checksum: String?
}
