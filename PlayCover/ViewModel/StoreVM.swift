//
//  Store.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 06/08/2022.
//

import Foundation
import Observation

@Observable
final class StoreVM {
    public static var shared: StoreVM { AppEnvironment.shared.store }
    @ObservationIgnored private let plistSource: URL

    init(plistSource: URL = PlayTools.playCoverContainer
            .appendingPathComponent("Sources")
            .appendingPathExtension("plist")) {
        self.plistSource = plistSource
        sourcesList = []
        if !decode() { encode() }
    }

    /// Starts fetching every source. Called once at launch by `AppEnvironment`.
    func bootstrap() {
        resolveSources()
    }

    var sourcesList: [SourceData] {
        didSet {
            encode()
        }
    }
    var sourcesData: [SourceJSON] = [] {
        didSet {
            updateSourcesApps()
        }
    }
    var sourcesApps: [SourceAppsData] = []

    @ObservationIgnored private var resolveTask: Task<Void, Never>?

    public func getEnabledSources() -> [SourceJSON] {
        return sourcesData.filter { sourceJSON in
            return sourcesList.contains { sourceData in
                sourceData.id == sourceJSON.id && sourceData.isEnabled
            }
        }
    }

    func enableSourceToggle(source: SourceData, value: Bool) {
        if let index = sourcesList.firstIndex(of: source) {
            sourcesList[index].isEnabled = value
        }
        updateSourcesApps()
    }

    func updateSourcesApps() {
        sourcesApps.removeAll()
        let enabledSources: [SourceJSON] = getEnabledSources()
        for source in enabledSources {
            appendSourceData(source)
        }
    }

    //
    func addSource(_ source: SourceData) {
        sourcesList.append(source)
        resolveSources()
    }

    //
    func deleteSource(_ selectedSource: inout Set<UUID>) {
        sourcesList.removeAll {
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

    //
    func resolveSources() {
        resolveTask?.cancel()
        resolveTask = Task { @MainActor in

            guard NetworkVM.isConnectedToNetwork() && !sourcesList.isEmpty else { return }

            let sourcesCount = sourcesList.count
            sourcesData.removeAll()

            for index in sourcesList.indices {
                sourcesList[index].status = .checking
                let (sourceJson, sourceState) = await getSourceData(sourceLink: sourcesList[index].source,
                                                                    sourceId: sourcesList[index].id)
                guard sourcesCount == sourcesList.count else { return }
                sourcesList[index].status = sourceState
                if sourceState == .valid, let sourceJson {
                    sourcesData.append(sourceJson)
                }
            }

        }
    }

    //
    func awaitResolveSources() async {
        guard let task = resolveTask else {
            return
        }
        _ = await task.result
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
    private func getSourceData(sourceLink: String, sourceId: UUID) async -> (SourceJSON?, SourceValidation) {
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
        do {
            return (try SourceJSON.decode(unwrappedData, from: url, id: sourceId), .valid)
        } catch {
            debugPrint("Error decoding data from URL: \(url): \(error)")
            return (nil, .badjson)
        }
    }

    //
    private func appendSourceData(_ source: SourceJSON) {
        for app in source.data where !sourcesApps.contains(where: { $0.bundleID == app.bundleID }) {
            sourcesApps.append(app)
        }
    }

}

// Source Data Structure
nonisolated struct SourceJSON: Codable, Equatable, Hashable, Sendable {
    let name: String
    let data: [SourceAppsData]
    let id: UUID

    /// The current source format. Its own `id` is ignored, and may be missing.
    private struct Document: Decodable {
        let name: String
        let data: [SourceAppsData]
    }

    /// Decodes a source document, falling back to the legacy format that is a bare list of apps.
    /// Legacy sources are named after the file (local sources) or the host (remote sources).
    ///
    /// The result always carries `id`, the identifier of the user's source entry it was fetched for:
    /// that is how enabled sources are matched, and a publisher's `id` can never equal it.
    static func decode(_ data: Data, from url: URL, id: UUID) throws -> SourceJSON {
        do {
            let document = try JSONDecoder().decode(Document.self, from: data)
            return SourceJSON(name: document.name, data: document.data, id: id)
        } catch {
            let apps = try JSONDecoder().decode([SourceAppsData].self, from: data)
            let name = url.isFileURL
                ? (url.absoluteString as NSString).lastPathComponent.replacingOccurrences(of: ".json", with: "")
                : url.host ?? url.absoluteString
            return SourceJSON(name: name, data: apps, id: id)
        }
    }
}

nonisolated struct SourceAppsData: Codable, Equatable, Hashable, Sendable {
    let bundleID: String
    let name: String
    let version: String
    let itunesLookup: String
    let link: String
    let checksum: String?
}
