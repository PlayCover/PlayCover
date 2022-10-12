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
    let accountInfoPlistEncrypt = "MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption"
    let kibanaReportArrayKeyEncrypt = "MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption"
    let lastAccountModelEncrypt = "MIHOYO_LAST_ACCOUNT_MODEL_Encryption"

    // Get path URL and create a folder with the content of uidInfo.txt
    let gameDataPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent(bundleID)
        .appendingPathComponent("Data")
        .appendingPathComponent("Documents")

    // Path to the folder where the data will be stored check if exists and if not create it
    let store = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent("io.playcover.PlayCover")
        .appendingPathComponent("Storage")
    let storePath = isGlobalVersion
                    ? store.appendingPathComponent(folderName)
                    : store.appendingPathComponent("Yuanshen \(folderName)")

    // Data to move from GameDataPath to StorePath
    let accountInfoPlistEncryptUrl = gameDataPath
        .appendingPathComponent(accountInfoPlistEncrypt)
    let kibanaReportArrayKeyEncryptUrl = gameDataPath
        .appendingPathComponent(kibanaReportArrayKeyEncrypt)
    let lastAccountModelEncryptUrl = gameDataPath
        .appendingPathComponent(lastAccountModelEncrypt)

    if !FileManager.default.fileExists(atPath: store.path) {
        do {
            try FileManager.default.createDirectory(atPath: store.path,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
            try FileManager.default.createDirectory(atPath: storePath.path,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
        } catch {
            Log.shared.error("Error creating store directory: \(error)")
        }
    } else {
        do {
            try FileManager.default.createDirectory(atPath: storePath.path,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
        } catch {
            Log.shared.error("Error creating game directory: \(error)")
        }
    }

    // Move data from GameDataPath to StorePath
    do {
        try FileManager.default.copyItem(at: accountInfoPlistEncryptUrl,
                                         to: storePath.appendingPathComponent(accountInfoPlistEncrypt))

        try FileManager.default.copyItem(at: kibanaReportArrayKeyEncryptUrl,
                                         to: storePath.appendingPathComponent(kibanaReportArrayKeyEncrypt))

        try FileManager.default.copyItem(at: lastAccountModelEncryptUrl,
                                         to: storePath.appendingPathComponent(lastAccountModelEncrypt))
        if isGlobalVersion {
            FileManager.default.createFile(atPath: storePath
                                                   .appendingPathComponent("region")
                                                   .appendingPathExtension("txt").path,
                                           contents: nil,
                                           attributes: nil)
            try accountRegion.write(to: storePath
                                        .appendingPathComponent("region")
                                        .appendingPathExtension("txt"),
                                    atomically: false,
                                    encoding: .utf8)
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

    // Path of plist file
    let url = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent("com.miHoYo.GenshinImpact")
        .appendingPathComponent("Data")
        .appendingPathComponent("Library")
        .appendingPathComponent("Preferences")
        .appendingPathComponent("com.miHoYo.GenshinImpact")
        .appendingPathExtension("plist")

    // Read plist file
    let data = try Data(contentsOf: url)

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
