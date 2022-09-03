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

    let gameDataPath = NSHomeDirectory() + "/Library/Containers/\(bundleID)/Data/Documents/"
    let storePath = NSHomeDirectory() + "/Library/Containers/io.playcover.PlayCover/Storage/" + folderName + "/"

    let accountInfoPlistEncryptUrl =
        URL(fileURLWithPath: gameDataPath + accountInfoPlistEncrypt)
    let kibanaReportArrayKeyEncryptUrl =
        URL(fileURLWithPath: gameDataPath + kibanaReportArrayKeyEncrypt)
    let lastAccountModelEncryptUrl =
        URL(fileURLWithPath: gameDataPath + lastAccountModelEncrypt)

    let fileManager = FileManager.default

    // remove existent user data from genshin impact

    do {
        try fileManager.removeItem(at: accountInfoPlistEncryptUrl )
        try fileManager.removeItem(at: kibanaReportArrayKeyEncryptUrl)
        try fileManager.removeItem(at: lastAccountModelEncryptUrl)
    } catch {
        Log.shared.log("Error removing file: \(error)")
    }

    // move data from StorePath to  GameDataPath
    do {
        try fileManager.copyItem(at: URL(fileURLWithPath: storePath + accountInfoPlistEncrypt),
                                 to: accountInfoPlistEncryptUrl)

        try fileManager.copyItem(at: URL(fileURLWithPath: storePath + kibanaReportArrayKeyEncrypt),
                                 to: kibanaReportArrayKeyEncryptUrl)

        try fileManager.copyItem(at: URL(fileURLWithPath: storePath + lastAccountModelEncrypt),
                                 to: lastAccountModelEncryptUrl)
        if isGlobalVersion {
            let region = try String(contentsOf: URL(fileURLWithPath: storePath + "region.txt"), encoding: .utf8)
            modifyPlist(newRegion: region)
        }
    } catch {
        Log.shared.log("Error moving file: \(error)")
    }
}

func modifyPlist(newRegion: String) {
    do {
        // path of plist file
        let staticUrl = "/Library/Containers/com.miHoYo.GenshinImpact/" +
            "Data/Library/Preferences/com.miHoYo.GenshinImpact.plist"
        let url = URL(fileURLWithPath: NSHomeDirectory() + staticUrl )
        // read plist file
        let data = try Data(contentsOf: url)

        guard var plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
                as? [String: Any] else { throw PlayCoverError.noGenshinAccount }

        guard let GENERAL_DATA = plist["GENERAL_DATA"] as? String else { throw PlayCoverError.noGenshinAccount }
        var modifiedValue = GENERAL_DATA
        // modified GENERAL_DATA
        let regions = ["os_usa", "os_euro", "os_asia", "os_cht"]

        for region in regions {
            modifiedValue = modifiedValue.replacingOccurrences(of: "\(region)",
                                                              with: "\(newRegion)",
                                                              options: .literal,
                                                              range: nil)
        }

        // write modified value to GENERAL_DATA key of plist
        plist["GENERAL_DATA"] = modifiedValue

        // write plist to file
        let plistData = try PropertyListSerialization.data(fromPropertyList: plist,
                                                           format: .xml,
                                                           options: 0)
        try plistData.write(to: url, options: .atomic)
    } catch {
        Log.shared.log("Error editing plist file: \(error)")
    }
}

func getAccountList () -> [String] {
    let storePath = NSHomeDirectory() + "/Library/Containers/io.playcover.PlayCover/Storage/"
    var accountStored: [String]
    do {
        accountStored = try FileManager.default.contentsOfDirectory(atPath: storePath)
    } catch {
        accountStored = []
    }
    return accountStored
}
