//
//  DeleteStoredGenshinUserData.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 23/07/22.
//
import Foundation

func deleteStoredAccount(folderName: String) {
    let folderPath = NSHomeDirectory() + "/Library/Containers/io.playcover.PlayCover/Storage/" + folderName
    // create folder using StorePath
    let fileManager = FileManager.default
    do {
        try fileManager.removeItem(atPath: folderPath)
    } catch {
        Log.shared.error("Error revoming stored folder: \(error)")
    }
}
