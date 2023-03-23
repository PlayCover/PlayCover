//
//  Store.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 06/08/2022.
//

import Foundation
import Semaphore

class StoreVM: ObservableObject, @unchecked Sendable {
    public static let shared = StoreVM()
    private let plistSource: URL

    private init() {
        plistSource = PlayTools.playCoverContainer
            .appendingPathComponent("Sources")
            .appendingPathExtension("plist")
        sourcesList = []
        if !decode() { encode() }
        Task {
            await resolveSources()
        }
    }

    @Published var sourcesData: [SourceJSON] = []
    @Published var sourcesList: [SourceData] {
        didSet {
            encode()
        }
    }

    //
    func addSource(_ source: SourceData) {
        sourcesList.append(source)
        sourcesData.removeAll()
        Task {
            await resolveSources()
        }
    }

    //
    func deleteSource(_ selectedSource: inout Set<UUID>) {
        sourcesList.removeAll {
            selectedSource.contains($0.id)
        }
        sourcesData.removeAll()
        Task {
            await resolveSources()
        }
    }

    //
    func moveSourceUp(_ selectedSource: inout Set<UUID>) {
        let selectedData = sourcesList.filter {
            selectedSource.contains($0.id)
        }

        if let first = selectedData.first {
            if var index = sourcesList.firstIndex(of: first) {
                if index == 0 {
                    return
                } else {
                    index -= 1
                    sourcesList.removeAll {
                        selectedSource.contains($0.id)
                    }
                    sourcesList.insert(contentsOf: selectedData, at: index)
                }
            }
        }
        sourcesData.removeAll()
        Task {
            await resolveSources()
        }
    }

    //
    func moveSourceDown(_ selectedSource: inout Set<UUID>) {
        let selectedData = sourcesList.filter {
            selectedSource.contains($0.id)
        }

        if let first = selectedData.first {
            if var index = sourcesList.firstIndex(of: first) {
                if index == sourcesList.endIndex {
                    return
                } else {
                    index += 1
                    sourcesList.removeAll {
                        selectedSource.contains($0.id)
                    }
                    sourcesList.insert(contentsOf: selectedData, at: index)
                }
            }
        }
        sourcesData.removeAll()
        Task {
            await resolveSources()
        }
    }

    //
    @MainActor func resolveSources() async {
        let semaphore = AsyncSemaphore(value: 0)
        guard NetworkVM.isConnectedToNetwork() else { return }
        if !sourcesList.isEmpty {
            for index in sourcesList.indices {
                sourcesList[index].status = .checking
                let (sourceJson, sourceState) = await getSourceData(sourceLink: sourcesList[index].source)
                sourcesList[index].status = sourceState
                if sourceState == .valid {
                    if let json = sourceJson {
                        sourcesData.append(json)
                        semaphore.signal()
                    }
                } else {
                    semaphore.signal()
                }
                await semaphore.wait()
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
        do {
            let (data, response) = try await URLSession.shared.data(
                for: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
            )
            if !url.isFileURL {
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { return (nil, .badurl) }
            }
            let jsonResult: SourceJSON = try JSONDecoder().decode(SourceJSON.self, from: data)
            debugPrint("SourceJSON from \(url) Fetched")
            return (jsonResult, .valid)
        } catch {
            do {
                let (data, response) = try await URLSession.shared.data(
                    for: URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
                )
                if !url.isFileURL {
                    guard (response as? HTTPURLResponse)?.statusCode == 200 else { return (nil, .badurl) }
                }
                let jsonResult: [SourceAppsData] = try JSONDecoder().decode([SourceAppsData].self, from: data)
                let newJson = SourceJSON(name: url.isFileURL ? "localhost" : url.host ?? url.absoluteString,
                                         logo: "NoLogo",
                                         data: jsonResult)
                return (newJson, .valid)
            } catch {
                debugPrint("Error decoding data from URL: \(url): \(error)")
                return (nil, .badjson)
            }
        }
    }
}

// Source Data Structure
struct SourceJSON: Codable, Equatable, Hashable {
    let name: String
    let logo: String
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
