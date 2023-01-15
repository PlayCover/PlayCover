//
//  DeleteStoredGenshinUserData.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 23/07/22.
//

import Foundation

func deleteStoredAccount(folderName: String) {
  //  let folderPath = NSHomeDirectory() + "/Library/Containers/io.playcover.PlayCover/Storage/" + folderName

    let folderPath = GenshinUserDataURLs.getStorePath().appendingEscapedPathComponent(folderName)

    do {
        try FileManager.default.removeItem(atPath: folderPath.path)
    } catch {
        Log.shared.error("Error revoming stored folder: \(error)")
    }
}
