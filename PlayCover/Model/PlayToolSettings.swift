//
//  PlayToolsVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/13/22.
//

import Foundation

struct PlayToolsAppData: Codable {
    var bundleID: String
    var hasPlayTools: Bool
}

class PlayToolSettings {

    static let shared = PlayToolSettings()

    @Published private var settings: [PlayToolsAppData] {
        didSet {
            encode()
        }
    }

    let settingsUrl: URL

    private init() {
        settingsUrl = PlayTools.playCoverContainer
            .appendingPathComponent("PlayTools")
            .appendingPathExtension("plist")

        settings = []

        if !decode() {
            encode()
        }
    }

    @discardableResult
    public func decode() -> Bool {
        do {
            let data = try Data(contentsOf: settingsUrl)
            settings = try PropertyListDecoder().decode([PlayToolsAppData].self, from: data)
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
            let data = try encoder.encode(settings)
            try data.write(to: settingsUrl)
            return true
        } catch {
            print(error)
            return false
        }
    }

    public func add(_ bundleID: String, _ hasPlayTools: Bool) {
        settings.append(PlayToolsAppData(bundleID: bundleID, hasPlayTools: hasPlayTools))
    }

    public func modify(_ bundleID: String, _ hasPlayTools: Bool) {
        if let appPos = settings.firstIndex(where: { $0.bundleID == bundleID }) {
            settings[appPos].hasPlayTools = hasPlayTools
        } else {
            add(bundleID, hasPlayTools)
        }
    }

    public func remove(_ bundleID: String) {
        settings = settings.filter({ $0.bundleID != bundleID })
    }

    public func get(_ bundleID: String) -> Bool? {
        if let appPos = settings.firstIndex(where: { $0.bundleID == bundleID }) {
            return settings[appPos].hasPlayTools
        } else {
            return nil
        }
    }

    public func has(_ bundleID: String) -> Bool {
        settings.filter({ $0.bundleID == bundleID }).count > 0
    }

}
