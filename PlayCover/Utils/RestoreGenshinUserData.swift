//
//  RestoreGenshinUserData.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 20/07/22.
//

import Foundation

func restoreUserData(folderName: String, app: PlayApp) {
    let bundleID = app.info.bundleIdentifier
    let isGlobalVersion = bundleID == "com.miHoYo.GenshinImpact"
    let accountInfoPlistEncrypt = "MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption"
    let kibanaReportArrayKeyEncrypt = "MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption"
    let lastAccountModelEncrypt = "MIHOYO_LAST_ACCOUNT_MODEL_Encryption"

    let gameDataPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent(bundleID)
        .appendingPathComponent("Data")
        .appendingPathComponent("Documents")
    
    let storePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent("io.playcover.PlayCover")
        .appendingPathComponent("Storage")
        .appendingPathComponent(folderName)

    let accountInfoPlistEncryptUrl = gameDataPath
        .appendingPathComponent(accountInfoPlistEncrypt)
    let kibanaReportArrayKeyEncryptUrl = gameDataPath
        .appendingPathComponent(kibanaReportArrayKeyEncrypt)
    let lastAccountModelEncryptUrl = gameDataPath
        .appendingPathComponent(lastAccountModelEncrypt)

    // Remove existent user data from genshin impact

    do {
        try FileManager.default.removeItem(at: accountInfoPlistEncryptUrl )
        try FileManager.default.removeItem(at: kibanaReportArrayKeyEncryptUrl)
        try FileManager.default.removeItem(at: lastAccountModelEncryptUrl)
    } catch {
        Log.shared.log("Error removing file: \(error)")
    }

    // Move data from StorePath to  GameDataPath
    do {
        try FileManager.default.copyItem(at: storePath
                                             .appendingPathComponent(accountInfoPlistEncrypt),
                                         to: accountInfoPlistEncryptUrl)

        try FileManager.default.copyItem(at: storePath
                                             .appendingPathComponent(kibanaReportArrayKeyEncrypt),
                                         to: kibanaReportArrayKeyEncryptUrl)

        try FileManager.default.copyItem(at: storePath
                                             .appendingPathComponent(lastAccountModelEncrypt),
                                         to: lastAccountModelEncryptUrl)
        if isGlobalVersion {
            let region = try String(contentsOf: storePath
                                                .appendingPathComponent("region")
                                                .appendingPathExtension("txt"),
                                    encoding: .utf8)
            modifyPlist(newRegion: region)
        }
    } catch {
        Log.shared.log("Error moving file: \(error)")
    }
}

func modifyPlist(newRegion: String) {
    do {
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

        guard var plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                as? [String: Any] else { throw PlayCoverError.noGenshinAccount }

        guard let GENERAL_DATA = plist["GENERAL_DATA"] as? String else { throw PlayCoverError.noGenshinAccount }
        var modifiedValue = GENERAL_DATA
        // Modified GENERAL_DATA
        let regions = ["os_usa", "os_euro", "os_asia", "os_cht"]

        for region in regions {
            modifiedValue = modifiedValue.replacingOccurrences(of: "\(region)",
                                                              with: "\(newRegion)",
                                                              options: .literal,
                                                              range: nil)
        }

        // Write modified value to GENERAL_DATA key of plist
        plist["GENERAL_DATA"] = modifiedValue

        // Write plist to file
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist,
                                                           format: .xml,
                                                           options: 0)
        try plistData.write(to: url, options: .atomic)
    } catch {
        Log.shared.log("Error editing plist file: \(error)")
    }
}

func getAccountList () -> [String] {
    let storePath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent("io.playcover.PlayCover")
        .appendingPathComponent("Storage")

    var accountStored: [String]
    do {
        accountStored = try FileManager.default.contentsOfDirectory(atPath: storePath.path)
    } catch {
        accountStored = []
    }
    return accountStored
}
