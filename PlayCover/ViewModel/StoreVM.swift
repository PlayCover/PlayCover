//
//  Store.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 06/08/2022.
//

import Foundation

class StoreVM: ObservableObject, @unchecked Sendable {
    public static let shared = StoreVM()
    private let plistSource: URL
    private let plistEnabledSource: URL
    private init() {
        plistSource = PlayTools.playCoverContainer
            .appendingPathComponent("Sources")
            .appendingPathExtension("plist")
        plistEnabledSource = PlayTools.playCoverContainer
            .appendingPathComponent("SourcesEnabled")
            .appendingPathExtension("plist")
        sourcesList = []
        enabledsourcesList = []
        if !decode() { encode() }
        if !decodeEnabled() {
            enabledsourcesList = sourcesList
            encodeEnabled()
        }
        resolveSources()
    }

    @Published var sourcesList: [SourceData] {
        didSet {
            encode()
        }
    }

    @Published var enabledsourcesList: [SourceData] {
        didSet {
            encodeEnabled()
        }
    }

    @Published var sourcesEnabledData: [SourceJSON] = [] {
        didSet {
            sourcesEnabeldApps.removeAll()
            for source in sourcesEnabledData {
                appendSourceEnabledData(source)
            }
        }
    }

    @Published var sourcesData: [SourceJSON] = [] {
        didSet {
            sourcesApps.removeAll()
            for source in sourcesData {
                appendSourceData(source)
            }
        }
    }

    @Published var sourcesApps: [SourceAppsData] = []
    @Published var sourcesEnabeldApps: [SourceAppsData] = []

    private var resolveTask: Task<Void, Never>?
    //
    func enableSourceToggle(_ source: SourceData, _ value: Bool) {
        if value && !enabledsourcesList.contains(where: { $0.source == source.source }) {
            enabledsourcesList.append(source)
        } else {
            enabledsourcesList = enabledsourcesList.filter { $0 != source }
        }
        updateEnabled()
    }
    //
    func addSource(_ source: SourceData) {
        sourcesList.append(source)
        enabledsourcesList.append(source)
        resolveSources()
    }

    //
    func deleteSource(_ selectedSource: inout Set<UUID>) {
        sourcesList.removeAll {
            selectedSource.contains($0.id)
        }
        enabledsourcesList.removeAll {
            selectedSource.contains($0.id)
        }
        resolveSources()
    }

    //
    func moveSourceUp(_ selectedSource: inout Set<UUID>) {
        let selected = sourcesList.filter {
            selectedSource.contains($0.id)
        }
        if let first = sourcesList.first,
           let data = selected.first {
            if data != first {
                if var index = sourcesList.firstIndex(of: data) {
                    index -= 1
                    sourcesList.removeAll {
                        selectedSource.contains($0.id)
                    }
                    sourcesList.insert(contentsOf: selected, at: index)
                }
                resolveSources()
            }
        }
    }

    //
    func moveSourceDown(_ selectedSource: inout Set<UUID>) {
        let selected = sourcesList.filter {
            selectedSource.contains($0.id)
        }

        if let last = sourcesList.last,
           let data = selected.first {
            if data != last {
                if var index = sourcesList.firstIndex(of: data) {
                    index += 1
                    sourcesList.removeAll {
                        selectedSource.contains($0.id)
                    }
                    sourcesList.insert(contentsOf: selected, at: index)
                }
                resolveSources()
            }
        }
    }

    func updateEnabled() {
        resolveTask?.cancel()
        resolveTask = Task { @MainActor in
            let sourcesEnabldeCount = enabledsourcesList.count
            sourcesEnabledData.removeAll()
            for index in enabledsourcesList.indices {
                enabledsourcesList[index].status = .checking
                let (sourceJsonEnabled, sourceStateEndabled) = await getSourceData(sourceLink:
                                                                                    enabledsourcesList[index].source)
                guard sourcesEnabldeCount == enabledsourcesList.count else { return }
                enabledsourcesList[index].status = sourceStateEndabled
                if sourceStateEndabled == .valid, let sourceJsonEnabled {
                    sourcesEnabledData.append(sourceJsonEnabled)
                }
            }
        }
    }

    //
    func resolveSources() {
        resolveTask?.cancel()
        resolveTask = Task { @MainActor in
            guard NetworkVM.isConnectedToNetwork() && !sourcesList.isEmpty else { return }
            let sourcesCount = sourcesList.count
            sourcesData.removeAll()
            for index in sourcesList.indices {
                sourcesList[index].status = .checking
                let (sourceJson, sourceState) = await getSourceData(sourceLink: sourcesList[index].source)
                guard sourcesCount == sourcesList.count else { return }
                sourcesList[index].status = sourceState
                if sourceState == .valid, let sourceJson {
                    sourcesData.append(sourceJson)
                }
            }
            //
            let sourcesEnabldeCount = enabledsourcesList.count
            sourcesEnabledData.removeAll()
            for index in enabledsourcesList.indices {
                enabledsourcesList[index].status = .checking
                let (sourceJsonEnabled, sourceStateEndabled) = await getSourceData(sourceLink:
                                                                                    enabledsourcesList[index].source)
                    guard sourcesEnabldeCount == enabledsourcesList.count else { return }
                    enabledsourcesList[index].status = sourceStateEndabled
                    if sourceStateEndabled == .valid, let sourceJsonEnabled {
                        sourcesEnabledData.append(sourceJsonEnabled)
                    }
                }
            }
    }

    //
    @discardableResult private func encodeEnabled() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(enabledsourcesList)
            try data.write(to: plistEnabledSource)
            return true
        } catch {
            print("StoreVM: Failed to encode SourcesEnabled.plist! ", error)
            return false
        }
    }

    //
    @discardableResult private func decodeEnabled() -> Bool {
        do {
            let data = try Data(contentsOf: plistEnabledSource)
            enabledsourcesList = try PropertyListDecoder().decode([SourceData].self, from: data)
            return true
        } catch {
            print("StoreVM: Failed to decode SourcesEnabled.plist! ", error)
            return false
        }
    }

    //
    @discardableResult private func encode() -> Bool {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(sourcesList)
            try data.write(to: plistSource)
            return true
        } catch {
            print("StoreVM: Failed to encode Sources.plist! ", error)
            return false
        }
    }

    //
    @discardableResult private func decode() -> Bool {
        do {
            let data = try Data(contentsOf: plistSource)
            sourcesList = try PropertyListDecoder().decode([SourceData].self, from: data)
            return true
        } catch {
            print("StoreVM: Failed to decode Sources.plist! ", error)
            return false
        }
    }

    //
    private func getSourceData(sourceLink: String) async -> (SourceJSON?, SourceValidation) {
        guard let url = URL(string: sourceLink) else { return (nil, .badurl) }
        var dataToDecode: Data?
        do {
            let (data, response) = try await URLSession.shared.data(
                for: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            )
            if !url.isFileURL {
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { return (nil, .badurl) }
            }
            dataToDecode = data
        } catch {
            debugPrint("Error decoding data from URL: \(url): \(error)")
            return (nil, .badjson)
        }
        guard let unwrappedData = dataToDecode else { return (nil, .badurl) }
        var decodedData: SourceJSON?
        do {
            decodedData = try JSONDecoder().decode(SourceJSON.self, from: unwrappedData)
            return (decodedData, .valid)
        } catch {
            do {
                let sourceName = url.isFileURL
                ? (url.absoluteString as NSString).lastPathComponent.replacingOccurrences(of: ".json", with: "")
                : url.host ?? url.absoluteString
                let oldTypeJson: [SourceAppsData] = try JSONDecoder().decode([SourceAppsData].self, from: unwrappedData)
                decodedData = SourceJSON(name: sourceName, data: oldTypeJson)
                return (decodedData, .valid)
            } catch {
                debugPrint("Error decoding data from URL: \(url): \(error)")
                return (nil, .badjson)
            }
        }
    }

    //
    private func appendSourceData(_ source: SourceJSON) {
        for app in source.data where !sourcesApps.contains(app) {
            sourcesApps.append(app)
        }
    }
    //
    private func appendSourceEnabledData(_ source: SourceJSON) {
        for app in source.data where !sourcesEnabeldApps.contains(app) {
            sourcesEnabeldApps.append(app)
        }
    }

}

// Source Data Structure
struct SourceJSON: Codable, Equatable, Hashable {
    let name: String
    let data: [SourceAppsData]
}

struct SourceAppsData: Codable, Equatable, Hashable {
    let bundleID: String
    let name: String
    let version: String
    let itunesLookup: String
    let link: String
    let checksum: String?
}
