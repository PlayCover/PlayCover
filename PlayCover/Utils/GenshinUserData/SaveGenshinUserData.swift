//
//  SaveGenshinUserData.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 20/07/22.
//

import Foundation
import SwiftUI

func storeUserData(folderName: String, accountRegion: String, app: PlayApp) {
    let bundleID = app.info.bundleIdentifier
    let isGlobalVersion = bundleID == "com.miHoYo.GenshinImpact"

    // Get path URL and create a folder with the content of uidInfo.txt
    let gameDataPath = GenshinUserDataURLs.getGameDataPath(bundleID: bundleID)

    // Path to the folder where the data will be stored check if exists and if not create it
    let store = GenshinUserDataURLs.getStorePath()
    let storePath = isGlobalVersion
                    ? store.appendingEscapedPathComponent(folderName)
                    : store.appendingEscapedPathComponent("Yuanshen \(folderName)")

    // Data to move from GameDataPath to StorePath
    let accountInfoPlistURL = gameDataPath.appendingPathComponent(GenshinUserDataURLs.accountInfoPlist)
    let kibanaReportArrayKeyURL = gameDataPath.appendingPathComponent(GenshinUserDataURLs.kibanaReportArrayKey)
    let lastAccountModelURL = gameDataPath.appendingPathComponent(GenshinUserDataURLs.lastAccountModel)

    if !FileManager.default.fileExists(atPath: store.path) {
        do {
            try FileManager.default.createDirectory(atPath: store.path,
                                                    withIntermediateDirectories: false, attributes: nil)
            try FileManager.default.createDirectory(atPath: storePath.path,
                                                    withIntermediateDirectories: false, attributes: nil)
        } catch {
            Log.shared.error("Error creating store directory: \(error)")
        }
    } else {
        do {
            try FileManager.default.createDirectory(atPath: storePath.path,
                                                    withIntermediateDirectories: false, attributes: nil)
        } catch {
            Log.shared.error("Error creating game directory: \(error)")
        }
    }

    // Move data from GameDataPath to StorePath
    do {
        try FileManager.default.copyItem(at: accountInfoPlistURL,
                                         to: storePath.appendingPathComponent(GenshinUserDataURLs.accountInfoPlist))

        try FileManager.default.copyItem(at: kibanaReportArrayKeyURL,
                                         to: storePath.appendingPathComponent(GenshinUserDataURLs.kibanaReportArrayKey))

        try FileManager.default.copyItem(at: lastAccountModelURL,
                                         to: storePath.appendingPathComponent(GenshinUserDataURLs.lastAccountModel))
        if isGlobalVersion {
            let txtURL = storePath.appendingPathComponent("region").appendingPathExtension("txt")
            FileManager.default.createFile(atPath: txtURL.path, contents: nil, attributes: nil)
            try accountRegion.write(to: txtURL, atomically: false, encoding: .utf8)
        }
    } catch {
        Log.shared.error("Error moving file: \(error)")
    }
}

func checkCurrentRegion(selectedRegion: String) throws -> Bool {
    let regionName: String

    if selectedRegion == "America" {
        regionName = "os_usa"
    } else if selectedRegion == "Europe" {
        regionName = "os_euro"
    } else if selectedRegion == "Asia" {
        regionName = "os_asia"
    } else {
        regionName = "os_cht"
    }

    // Read plist file
    let data = try Data(contentsOf: GenshinUserDataURLs.plistPath)

    guard let plist = try PropertyListSerialization
        .propertyList(from: data, options: [], format: nil)
            as? [String: Any] else { throw PlayCoverError.noGenshinAccount }

    guard let value = plist["GENERAL_DATA"] as? String else { throw PlayCoverError.noGenshinAccount }

    // Check if selected region is in the region of the plist
    // "The current account is set to a different server, enter the game"
    if value.contains(regionName) {
        return true
    } else {
        return false
    }
}
