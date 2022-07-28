//
//  SaveGenshinUserData.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 20/07/22.
//
// swiftlint:disable all

import Foundation
import SwiftUI

func storeUserData( folderName: String, accountRegion: String ){
        let MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption = "MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption"
        let MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption = "MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption"
        let MIHOYO_LAST_ACCOUNT_MODEL_Encryption = "MIHOYO_LAST_ACCOUNT_MODEL_Encryption"

        //get Path URL and create a folder with the content of uidInfo.txt
        let gameDataPath = NSHomeDirectory() + "/Library/Containers/com.miHoYo.GenshinImpact/Data/Documents/"
        
        //Path to the folder where the data will be stored check if exists and if not create it
        let store = NSHomeDirectory() + "/Library/Containers/io.playcover.PlayCover/storage/"
        let storePath = NSHomeDirectory() + "/Library/Containers/io.playcover.PlayCover/storage/" + folderName + "/"

        // Data to move from GameDataPath to StorePath
        let MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption_URL = URL(fileURLWithPath: gameDataPath + MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption)
        let MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption_URL = URL(fileURLWithPath: gameDataPath + MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption)
        let MIHOYO_LAST_ACCOUNT_MODEL_Encryption_URL = URL(fileURLWithPath: gameDataPath + MIHOYO_LAST_ACCOUNT_MODEL_Encryption)

        // create folder using StorePath
        let fileManager = FileManager.default
    
        if !fileManager.fileExists(atPath: store) {
            do {
                try fileManager.createDirectory(atPath: store, withIntermediateDirectories: false, attributes: nil)
                try fileManager.createDirectory(atPath: storePath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Error creating store directory: \(error)")
            }
        } else {
            do {
                try fileManager.createDirectory(atPath: storePath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Error creating game directory: \(error)")
            }
        }
    
        // move data from GameDataPath to StorePath
        do {
            try fileManager.copyItem(at: MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption_URL,
                                     to: URL(fileURLWithPath: storePath + MIHOYO_ACCOUNT_INFO_PLIST_2_Encryption))
            
            try fileManager.copyItem(at: MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption_URL,
                                     to: URL(fileURLWithPath: storePath + MIHOYO_KIBANA_REPORT_ARRAY_KEY_Encryption))
            
            try fileManager.copyItem(at: MIHOYO_LAST_ACCOUNT_MODEL_Encryption_URL,
                                     to: URL(fileURLWithPath: storePath + MIHOYO_LAST_ACCOUNT_MODEL_Encryption))
            fileManager.createFile(atPath: storePath + "region.txt", contents: nil, attributes: nil)
            try accountRegion.write(to: URL(fileURLWithPath:storePath + "region.txt"), atomically: false, encoding: .utf8)
            
        } catch {
            print("Error moving file: \(error)")
        }

}

func checkCurrentRegion (selectedRegion:String) -> Bool {
    let regionName = selectedRegion == "America" ? "os_usa" : "os_euro"
    // plist path
    let url = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Containers/com.miHoYo.GenshinImpact/Data/Library/Preferences/com.miHoYo.GenshinImpact.plist")

    // read plist file
    // swiftlint:disable:next force_try
    let data = try! Data(contentsOf: url)
    // swiftlint:disable:next all
    let plist = try! PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
    // swiftlint:disable:next force_cast
    let value = plist["GENERAL_DATA"] as! String

    // Check if selected region is in the region of the plist
    // "The current account is set to a different server, enter the game"
        if value.contains(regionName) {
            return true
        } else {
            return false
        }
}
