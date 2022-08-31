//
//  SaveGenshinUserData.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 20/07/22.
//

import Foundation
import SwiftUI

func storeUserData( folderName: String, accountRegion: String, app: PlayApp ) {
        let bundleID = app.info.bundleIdentifier
        let isGlobalVersion = bundleID == "com.miHoYo.GenshinImpact"
        let accountInfoPlistEncrypt = "MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption"
        let kibanaReportArrayKeyEncrypt = "MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption"
        let lastAccountModelEncrypt = "MIHOYO_LAST_ACCOUNT_MODEL_Encryption"

        // get Path URL and create a folder with the content of uidInfo.txt
        let gameDataPath = NSHomeDirectory() + "/Library/Containers/\(bundleID)/Data/Documents/"

        // Path to the folder where the data will be stored check if exists and if not create it
        let store = NSHomeDirectory() + "/Library/Containers/io.playcover.PlayCover/Storage/"
        let storePath = isGlobalVersion
                        ? store + folderName + "/"
                        : store + "Yuanshen " + folderName + "/"

        // Data to move from GameDataPath to StorePath
        let accountInfoPlistEncryptUrl =
            URL(fileURLWithPath: gameDataPath + accountInfoPlistEncrypt)
        let kibanaReportArrayKeyEncryptUrl =
            URL(fileURLWithPath: gameDataPath + kibanaReportArrayKeyEncrypt)
        let lastAccountModelEncryptUrl =
            URL(fileURLWithPath: gameDataPath + lastAccountModelEncrypt)

        // create folder using StorePath
        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: store) {
            do {
                try fileManager.createDirectory(atPath: store, withIntermediateDirectories: false, attributes: nil)
                try fileManager.createDirectory(atPath: storePath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                Log.shared.error("Error creating store directory: \(error)")
            }
        } else {
            do {
                try fileManager.createDirectory(atPath: storePath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                Log.shared.error("Error creating game directory: \(error)")
            }
        }

        // move data from GameDataPath to StorePath
        do {
            try fileManager.copyItem(at: accountInfoPlistEncryptUrl,
                                     to: URL(fileURLWithPath: storePath + accountInfoPlistEncrypt))

            try fileManager.copyItem(at: kibanaReportArrayKeyEncryptUrl,
                                     to: URL(fileURLWithPath: storePath + kibanaReportArrayKeyEncrypt))

            try fileManager.copyItem(at: lastAccountModelEncryptUrl,
                                     to: URL(fileURLWithPath: storePath + lastAccountModelEncrypt))
            if isGlobalVersion {
                fileManager.createFile(atPath: storePath + "region.txt", contents: nil, attributes: nil)
                try accountRegion.write(to: URL(fileURLWithPath: storePath + "region.txt"),
                                        atomically: false, encoding: .utf8)
            }
        } catch { Log.shared.error("Error moving file: \(error)") }

}

func checkCurrentRegion (selectedRegion: String) throws -> Bool {
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

    // plist path
    let url = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Containers/com.miHoYo.GenshinImpact/" +
                  "Data/Library/Preferences/com.miHoYo.GenshinImpact.plist")

    // read plist file
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
