//
//  Store.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 06/08/2022.
//

import Foundation

class StoreVM: ObservableObject {

    static let shared = StoreVM()

    private init() {
        sourcesUrl = PlayTools.playCoverContainer
            .appendingPathComponent("Sources")
            .appendingPathExtension("plist")
        keymappingSourcesUrl = PlayTools.playCoverContainer
            .appendingPathComponent("KeymappingSources")
            .appendingPathExtension("plist")
        sources = []
        keymappingSources = []
        if !decode() {
            encode()
        }
        if !decode(source: keymappingSources) {
            encode(source: keymappingSources)
        }
        resolveSources()
    }

    @Published var apps: [StoreAppData] = []
    @Published var filteredApps: [StoreAppData] = []
    @Published var sources: [SourceData] {
        didSet {
            encode()
        }
    }
    @Published var keymappingSources: [SourceData] {
        didSet {
            encode(source: keymappingSources)
        }
    }

    let sourcesUrl: URL
    let keymappingSourcesUrl: URL

    @discardableResult
    public func decode(source: [SourceData]? = nil) -> Bool {
        do {
            if source == sources || source == nil {
                let data = try Data(contentsOf: sourcesUrl)
                sources = try PropertyListDecoder().decode([SourceData].self, from: data)
            } else if source == keymappingSources {
                let keymappingData = try Data(contentsOf: keymappingSourcesUrl)
                keymappingSources = try PropertyListDecoder().decode([SourceData].self, from: keymappingData)
            }

            return true
        } catch {
            print(error)
            return false
        }
    }

    @discardableResult
    public func encode(source: [SourceData]? = nil) -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            if source == sources || source == nil {
                let data = try encoder.encode(sources)
                try data.write(to: sourcesUrl)
            } else if source == keymappingSources {
                let keymappingData = try encoder.encode(keymappingSources)
                try keymappingData.write(to: keymappingSourcesUrl)
            }

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
        var result = apps
        if !uif.searchText.isEmpty {
            result = result.filter({
                $0.name.lowercased().contains(uif.searchText.lowercased())
            })
        }
        filteredApps = result
    }

    func resolveSources() {
        apps.removeAll()
        for index in 0..<sources.endIndex {
            sources[index].status = .checking
            DispatchQueue.global(qos: .userInteractive).async {
                if let url = URL(string: self.sources[index].source) {
                    if StoreVM.checkAvaliability(url: url) {
                        do {
                            let contents = try String(contentsOf: url)
                            let jsonData = contents.data(using: .utf8)!
                            do {
                                let data: [StoreAppData] = try JSONDecoder().decode([StoreAppData].self, from: jsonData)
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
                DispatchQueue.main.async {
                    self.sources[index].status = .badurl
                }
                return
            }
        }
        fetchApps()
    }

    func deleteSource(_ selected: inout Set<UUID>, source: [SourceData]? = nil) {
        if source == sources || source == nil {
            self.sources.removeAll(where: { selected.contains($0.id) })
        } else if source == keymappingSources {
            self.keymappingSources.removeAll(where: { selected.contains($0.id) })
        }
        selected.removeAll()
        resolveSources()
    }

    func moveSourceUp(_ selected: inout Set<UUID>, source: [SourceData]? = nil) {
        if source == sources || source == nil {
            let selectedData = self.sources.filter({ selected.contains($0.id) })
            var index = self.sources.firstIndex(of: selectedData.first!)! - 1
            self.sources.removeAll(where: { selected.contains($0.id) })
            if index < 0 {
                index = 0
            }
            self.sources.insert(contentsOf: selectedData, at: index)
        } else if source == keymappingSources {
            let selectedData = self.keymappingSources.filter({ selected.contains($0.id) })
            var index = self.keymappingSources.firstIndex(of: selectedData.first!)! - 1
            self.keymappingSources.removeAll(where: { selected.contains($0.id) })
            if index < 0 {
                index = 0
            }
            self.keymappingSources.insert(contentsOf: selectedData, at: index)
        }
    }

    func moveSourceDown(_ selected: inout Set<UUID>, source: [SourceData]? = nil) {
        if source == sources || source == nil {
            let selectedData = self.sources.filter({ selected.contains($0.id) })
            var index = self.sources.firstIndex(of: selectedData.first!)! + 1
            self.sources.removeAll(where: { selected.contains($0.id) })
            if index > self.sources.endIndex {
                index = self.sources.endIndex
            }
            self.sources.insert(contentsOf: selectedData, at: index)
        } else if source == keymappingSources {
            let selectedData = self.keymappingSources.filter({ selected.contains($0.id) })
            var index = self.keymappingSources.firstIndex(of: selectedData.first!)! + 1
            self.keymappingSources.removeAll(where: { selected.contains($0.id) })
            if index > self.keymappingSources.endIndex {
                index = self.keymappingSources.endIndex
            }
            self.keymappingSources.insert(contentsOf: selectedData, at: index)
        }
    }

    func appendSourceData(_ data: SourceData, source: [SourceData]? = nil) {
        if source == sources || source == nil {
            self.sources.append(data)
        } else if source == keymappingSources {
            self.keymappingSources.append(data)
        }
        self.resolveSources()
    }

    static func checkAvaliability(url: URL) -> Bool {
        var avaliable = true
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        URLSession(configuration: .default)
            .dataTask(with: request) { _, response, error in
                guard error == nil else {
                    print("Error:", error ?? "")
                    avaliable = false
                    return
                }

                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    print("down")
                    avaliable = false
                    return
                }
            }
            .resume()
        return avaliable
    }
}

struct StoreAppData: Codable, Equatable {
    var bundleID: String
    let name: String
    let version: String
    let itunesLookup: String
    let link: String
}
