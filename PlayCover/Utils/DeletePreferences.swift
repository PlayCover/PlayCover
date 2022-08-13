//
//  DeletePreferences.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 12/08/22.
//

import Foundation

func deletePreferences(app: String) {
    let plist = "/Users/\(NSUserName())/Library/Containers/\(app)/Data/Library/Preferences/\(app).plist"
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: plist)
    } catch {
        Log.shared.error("Error removing preferences: \(error)")
    }
}
