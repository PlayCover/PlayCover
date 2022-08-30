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
            try fileMgr.delete(at: containerUrl)
        } catch {
            Log.shared.error(error)
        }
    }

    public static func containers() throws -> [String: AppContainer] {
        var found = [String: AppContainer]()

        let directoryContents = try FileManager.default
            .contentsOfDirectory(at: CONTAINERS_PATH, includingPropertiesForKeys: nil, options: [])

        let subdirs = directoryContents.filter { $0.hasDirectoryPath }
        for sub in subdirs {
            let metadataPlist = sub.appendingPathComponent(".com.apple.containermanagerd.metadata.plist")

            if fileMgr.fileExists(atPath: metadataPlist.path) {
                if let plist = NSDictionary(contentsOfFile: metadataPlist.path) {
                    if let bundleId = plist["MCMMetadataIdentifier"] as? String {
                        found[bundleId] = AppContainer(bundleId: bundleId, containerUrl: sub)
                    }
                }
            }
        }

        return found
    }

    private static let CONTAINERS_PATH = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers")

}
