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
    var enableList: [String] = UserDefaults.standard.stringArray(forKey: "enableSourceList") ?? []
    private init() {
        plistSource = PlayTools.playCoverContainer
            .appendingPathComponent("Sources")
            .appendingPathExtension("plist")
        sourcesList = []
        if !decode() { encode() }
        resolveSources()
    }

    @Published var enabledList: [String] = (UserDefaults.standard.stringArray(forKey: "enableSourceList") ??
                                             StoreVM.shared.sourcesList.map { $0.source })

    @Published var sourcesList: [SourceData] {
        didSet {
            encode()
        }
    }
    @Published var sourcesData: [SourceJSON] = [] {
        didSet {
            sourcesApps.removeAll()
            let enabledSources: [SourceJSON] = sourcesData.filter { enabledList.contains($0.sourceURL) }
              for source in enabledSources {
                    appendSourceData(source)
                }
        }
    }
    @Published var sourcesApps: [SourceAppsData] = []

    private var resolveTask: Task<Void, Never>?

    //
    func enableSourceToggle(source: SourceData, value: Bool) {
        if enabledList.contains(source.source) && !value {
            enabledList.removeFirstObject(object: source.source)
        } else {
            enabledList.append(source.source)
        }
        UserDefaults.standard.set(enabledList, forKey: "enableSourceList")
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

    /*
    //
    @MainActor func asyncresolveSources() async {
        guard NetworkVM.isConnectedToNetwork() && !sourcesList.isEmpty else { return }
        let sourcesCount = sourcesList.count
        sourcesData.removeAll()
        for index in sourcesList.indices where enabledList.contains(sourcesList[index].source) {
            sourcesList[index].status = .checking
            let (sourceJson, sourceState) = await getSourceData(sourceLink: sourcesList[index].source)
            guard sourcesCount == sourcesList.count else { return }
            sourcesList[index].status = sourceState
            if sourceState == .valid, let sourceJson {
                sourcesData.append(sourceJson)
            }
        }
    }
*/
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
                decodedData = SourceJSON(name: sourceName, data: oldTypeJson, sourceURL: sourceLink)
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

}

// Source Data Structure
struct SourceJSON: Codable, Equatable, Hashable {
    let name: String
    let data: [SourceAppsData]
    let sourceURL: String
}

struct SourceAppsData: Codable, Equatable, Hashable {
    let bundleID: String
    let name: String
    let version: String
    let itunesLookup: String
    let link: String
    let checksum: String?
}

extension Array where Element == String {
    mutating func removeFirstObject(object: String) {
        guard let index = firstIndex(where: {$0 == object}) else { return }
        remove(at: index)
    }
}
