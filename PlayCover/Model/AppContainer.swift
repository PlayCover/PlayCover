//
//  ContainersParser.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 07.12.2021.
//

import Foundation

struct AppContainer {

    let bundleId: String
    let containerUrl: URL
    private static let containersURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")

    lazy var userPrefsUrl: URL = {
        return containerUrl
            .appendingPathComponent("Data")
            .appendingPathComponent("Library")
            .appendingPathComponent("Preferences")
            .appendingPathComponent(bundleId)
            .appendingPathExtension("plist")
    }()

    public func clear() {
        do {
            try FileManager.default.delete(at: containerUrl)
        } catch {
            Log.shared.error(error)
        }
    }

    public static func containers() throws -> [String: AppContainer] {
        var found = [String: AppContainer]()

        let directoryContents = try FileManager.default
            .contentsOfDirectory(at: containersURL, includingPropertiesForKeys: nil, options: [])

        let subdirs = directoryContents.filter { $0.hasDirectoryPath }
        for sub in subdirs {
            let metadataPlist = sub.appendingPathComponent(".com.apple.containermanagerd.metadata.plist")

            if FileManager.default.fileExists(atPath: metadataPlist.path) {
                if let plist = NSDictionary(contentsOfFile: metadataPlist.path) {
                    if let bundleId = plist["MCMMetadataIdentifier"] as? String {
                        found[bundleId] = AppContainer(bundleId: bundleId, containerUrl: sub)
                    }
                }
            }
        }

        return found
    }
}
