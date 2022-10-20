//
//  SourceVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 18/10/2022.
//

import Foundation

class SourceVM: ObservableObject {
    let sourceUrl: URL

    init(_ url: URL) {
        sourceUrl = url
        sources = []
        if !decode() {
            encode()
        }
        resolveSources()
    }

    @Published var sources: [SourceData] {
        didSet {
            encode()
        }
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: self.sourceUrl)
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
            try data.write(to: sourceUrl)

            return true
        } catch {
            print(error)
            return false
        }
    }

    func resolveSources() {}

    func deleteSource(_ selected: inout Set<UUID>) {
        self.sources.removeAll(where: { selected.contains($0.id) })
        selected.removeAll()
        resolveSources()
    }

    func moveSourceUp(_ selected: inout Set<UUID>) {
        let selectedData = self.sources.filter({ selected.contains($0.id) })
        var index = self.sources.firstIndex(of: selectedData.first!)! - 1
        self.sources.removeAll(where: { selected.contains($0.id) })
        if index < 0 {
            index = 0
        }
        self.sources.insert(contentsOf: selectedData, at: index)
    }

    func moveSourceDown(_ selected: inout Set<UUID>) {
        let selectedData = self.sources.filter({ selected.contains($0.id) })
        var index = self.sources.firstIndex(of: selectedData.first!)! + 1
        self.sources.removeAll(where: { selected.contains($0.id) })
        if index > self.sources.endIndex {
            index = self.sources.endIndex
        }
        self.sources.insert(contentsOf: selectedData, at: index)
    }

    func appendSourceData(_ data: SourceData) {
        if self.sources.contains(where: { $0.source == data.source }) {
            Log.shared.error("This URL already exists!")
            return
        }

        self.sources.append(data)
        self.resolveSources()
    }
}

struct SourceData: Identifiable, Hashable {
    var id = UUID()
    var source: String
    var status: SourceValidation = .valid

    enum SourceDataKeys: String, CodingKey {
        case source
    }
}

extension SourceData: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SourceDataKeys.self)
        try container.encode(source, forKey: .source)
    }
}

extension SourceData: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: SourceDataKeys.self)
        source = try values.decode(String.self, forKey: .source)
    }
}
