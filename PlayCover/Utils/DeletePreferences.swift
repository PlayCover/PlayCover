//
//  DeletePreferences.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 12/08/22.
//

import Foundation

func deletePreferences(app: String) {
    let plistURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent(app)
        .appendingPathComponent("Data")
        .appendingPathComponent("Library")
        .appendingPathComponent("Preferences")
        .appendingPathComponent(app)
        .appendingPathExtension("plist")

    guard FileManager.default.fileExists(atPath: plistURL.path) else { return }

    do {
        try FileManager.default.removeItem(atPath: plistURL.path)
    } catch {
        Log.shared.log("\(error)", isError: true)
    }
}
