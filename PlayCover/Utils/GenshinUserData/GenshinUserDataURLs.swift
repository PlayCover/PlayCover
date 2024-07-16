//
//  GenshinUserDataURLs.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 11/10/2022.
//

import Foundation

class GenshinUserDataURLs {
    static let accountInfoPlist = "MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption"
    static let kibanaReportArrayKey = "MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption"
    static let lastAccountModel = "MIHOYO_LAST_ACCOUNT_MODEL_Encryption"

    static let plistPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent("com.miHoYo.GenshinImpact")
        .appendingPathComponent("Data")
        .appendingPathComponent("Library")
        .appendingPathComponent("Preferences")
        .appendingPathComponent("com.miHoYo.GenshinImpact")
        .appendingPathExtension("plist")

    static func getGameDataPath(bundleID: String) -> URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent(bundleID)
            .appendingPathComponent("Data")
            .appendingPathComponent("Documents")
    }

    static func getStorePath() -> URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("io.playcover.PlayCover")
            .appendingPathComponent("Storage")
    }
}
