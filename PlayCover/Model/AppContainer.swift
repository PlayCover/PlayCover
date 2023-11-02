//
//  AppContainer.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 07.12.2021.
//

import Foundation

struct AppContainer {

    private static let containersURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")

    let bundleId: String
    var containerUrl: URL {
        AppContainer.containersURL.appendingPathComponent(bundleId)
    }

    var userPrefsUrl: URL {
        containerUrl.appendingPathComponent("Data")
            .appendingPathComponent("Library")
            .appendingPathComponent("Preferences")
            .appendingPathComponent(bundleId)
            .appendingPathExtension("plist")
    }

    init(bundleId: String) {
        self.bundleId = bundleId
    }

    public func clear() {
        FileManager.default.delete(at: containerUrl)
    }

    public func doesExist() -> Bool {
        FileManager.default.fileExists(atPath: containerUrl.path)
    }
}
