//
//  KeyCover.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import Foundation
import CryptoKit
import SwiftUI

struct KeyCover {
    static var shared = KeyCover()

    // This is only exposed at runtime
    var keyCoverPlainTextKey: String?
    var masterKeyFile = PlayTools.playCoverContainer.appendingPathComponent("ChainMaster.key")
    func isKeyCoverEnabled() -> Bool {
        return FileManager.default.fileExists(atPath: PlayTools.playCoverContainer
            .appendingPathComponent("ChainMaster.key").path)
    }

    func listKeychains() -> [KeyCoverKey] {
        // Enumerate all the keychains
        let keychains = try? FileManager.default
            .contentsOfDirectory(at: PlayTools.playCoverContainer.appendingPathComponent("PlayChain"),
                                 includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        var keychainList: [KeyCoverKey] = []
        for keychain in keychains ?? [] {
            let keychainName = keychain.lastPathComponent
                .replacingOccurrences(of: ".\(KeyCoverKey.encryptedKeyExtension)", with: "")
            let keychain = KeyCoverKey(appBundleID: keychainName)
            keychainList.append(keychain)
        }
        return keychainList
    }

    func unlockedCount() -> Int {
        var count = 0
        for keychain in listKeychains() where !keychain.chainEncryptionStatus {
            count += 1
        }
        return count
    }

    func unlockChain(_ keychain: KeyCoverKey) throws {
        if keyCoverPlainTextKey == nil {
            DispatchQueue.main.sync {
                KeyCoverObservable.shared.isKeyCoverUnlockingPromptShown = true
            }
            while KeyCoverObservable.shared.isKeyCoverUnlockingPromptShown {
                sleep(1)
            }
        }
        if keychain.chainEncryptionStatus {
            try? keychain.decryptKeyFolder()
        }
    }

    func lockChain(_ keychain: KeyCoverKey) throws {
        if keyCoverPlainTextKey == nil {
            return
        }
        if !keychain.chainEncryptionStatus {
            try? keychain.encryptKeyFolder()
        }
    }

    func lockAllChainsAsync() {
        DispatchQueue.global(qos: .background).async {
            for keychain in KeyCover.shared.listKeychains() where !keychain.chainEncryptionStatus {
                try? keychain.encryptKeyFolder()
            }
        }
    }

    mutating func resetKeyCover() throws {
        // Only available if KeyCover is enabled
        // and no chains are unlocked
        if isKeyCoverEnabled() && unlockedCount() == 0 {
            // Delete the master key
            try FileManager.default.removeItem(at: masterKeyFile)
            // Delete all the keychains
            try FileManager.default.removeItem(at: PlayTools.playCoverContainer.appendingPathComponent("PlayChain"))
        }
    }
}

class KeyCoverObservable: ObservableObject {
    static var shared = KeyCoverObservable()

    @Published var keyCoverEnabled = KeyCover.shared.isKeyCoverEnabled()
    @Published var unlockedCount = KeyCover.shared.unlockedCount()
    @Published var keychains = KeyCover.shared.listKeychains()
    
    @Published var isKeyCoverUnlockingPromptShown = KeyCoverPreferences.shared.promptForMasterPasswordAtLaunch

    func update() {
        keyCoverEnabled = KeyCover.shared.isKeyCoverEnabled()
        unlockedCount = KeyCover.shared.unlockedCount()
        keychains = KeyCover.shared.listKeychains()
    }
}

struct KeyCoverKey {
    static let encryptedKeyExtension = "keyCover"

    var keyFolderPath = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")
    var appBundleID: String
    var encryptedKeyFile: URL {
        return keyFolderPath
            .appendingPathComponent("\(appBundleID).\(KeyCoverKey.encryptedKeyExtension)")
    }

    var chainEncryptionStatus: Bool {
        return FileManager.default.fileExists(atPath: encryptedKeyFile.path)
    }

    func encryptKeyFolder() throws {
        if KeyCover.shared.keyCoverPlainTextKey == nil {
            return
        }
        // zip up the key folder
        // make sure to only compress the key folder, not the entire path to it
        let source = keyFolderPath.appendingPathComponent(appBundleID)
        let destination = keyFolderPath.appendingPathComponent("\(appBundleID).zip")
        let task = Process()
        task.launchPath = "/usr/bin/zip"
        task.currentDirectoryPath = keyFolderPath.path
        task.arguments = ["-r", destination.path, source.lastPathComponent]
        task.launch()
        task.waitUntilExit()

        // encrypt the zip file
        let task2 = Process()
        task2.launchPath = "/usr/bin/openssl"
        task2.currentDirectoryPath = keyFolderPath.path
        task2.arguments = ["enc", "-aes-256-cbc", "-A",
                            "-in", destination.path,
                            "-out", encryptedKeyFile.path,
                            "-k", KeyCover.shared.keyCoverPlainTextKey!]
        task2.launch()
        task2.waitUntilExit()

        // delete the zip file
        try? FileManager.default.removeItem(at: destination)

        // delete the key folder
        try? deleteKeyFolder()

        DispatchQueue.main.async {
            KeyCoverObservable.shared.update()
        }
    }

    func decryptKeyFolder() throws {
        if KeyCover.shared.keyCoverPlainTextKey == nil {
            return
        }
        // decrypt the zip file
        let task = Process()
        task.launchPath = "/usr/bin/openssl"
        task.arguments = ["enc", "-aes-256-cbc", "-A", "-d", "-in", encryptedKeyFile.path, "-out",
                          keyFolderPath.appendingPathComponent("\(appBundleID).zip").path,
                          "-k", KeyCover.shared.keyCoverPlainTextKey!]
        task.launch()
        task.waitUntilExit()

        // unzip the zip file
        let task2 = Process()
        task2.launchPath = "/usr/bin/unzip"
        task2.currentDirectoryPath = keyFolderPath.path
        task2.arguments = ["-o", keyFolderPath.appendingPathComponent("\(appBundleID).zip").path,
                           "-d", keyFolderPath.path]
        task2.launch()
        task2.waitUntilExit()

        // delete the zip file
        try? FileManager.default.removeItem(at: keyFolderPath.appendingPathComponent("\(appBundleID).zip"))

        // delete the encrypted key file
        try? FileManager.default.removeItem(at: encryptedKeyFile)

        DispatchQueue.main.async {
            KeyCoverObservable.shared.update()
        }
    }

    func deleteKeyFolder() throws {
        try? FileManager.default.removeItem(at: keyFolderPath.appendingPathComponent(appBundleID))
    }
}

class KeyCoverMaster {
    static func hashKey(_ key: String) -> String {
        let data = Data(key.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    static func validateMasterKey(_ key: String) -> Bool {
        // open the master key file
        let masterKeyFile = PlayTools.playCoverContainer.appendingPathComponent("ChainMaster.key")
        guard let masterKeyData = try? Data(contentsOf: masterKeyFile) else {
            return false
        }
        let hashedInputKey = hashKey(key)

        // compare it to the hash saved in the file
        return hashedInputKey == String(data: masterKeyData, encoding: .utf8)
    }

    static func setMasterKey(_ key: String) {
        // first check if there is a master key file
        let masterKeyFile = PlayTools.playCoverContainer.appendingPathComponent("ChainMaster.key")
        let keyExists = FileManager.default.fileExists(atPath: masterKeyFile.path)
        // if the key file does exist, decrypt everything first
        if keyExists {
            let keyFolder = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")
            let enumerator = FileManager.default.enumerator(at: keyFolder, includingPropertiesForKeys: nil,
                                                            options: [.skipsHiddenFiles,
                                                                      .skipsPackageDescendants,
                                                                      .skipsSubdirectoryDescendants],
                                                            errorHandler: nil)

            // decrypt each key folder
            while let file = enumerator?.nextObject() as? URL {
                if file.pathExtension == KeyCoverKey.encryptedKeyExtension {
                    let keyCover = KeyCoverKey(appBundleID: file.deletingPathExtension().lastPathComponent)
                    try? keyCover.decryptKeyFolder()
                }
            }
        }

        // write the new master key
        let hashedKey = hashKey(key)
        try? hashedKey.write(to: masterKeyFile, atomically: true, encoding: .utf8)

        // enumerate the file in the key folder
        let keyFolder = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")
        let enumerator = FileManager.default.enumerator(at: keyFolder, includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles,
                                                                  .skipsPackageDescendants,
                                                                  .skipsSubdirectoryDescendants],
                                                        errorHandler: nil)
        KeyCover.shared.keyCoverPlainTextKey = key
        // encrypt each key folder with the new key
        var isDir = ObjCBool(true)
        while let file = enumerator?.nextObject() as? URL {
            if FileManager.default.fileExists(atPath: file.path, isDirectory: &isDir) && isDir.boolValue {
                let keyCover = KeyCoverKey(appBundleID: file.lastPathComponent)
                try? keyCover.encryptKeyFolder()
            }
        }

        DispatchQueue.main.async {
            KeyCoverObservable.shared.update()
        }
    }

    static func removeMasterKey() {
        // decrypt all chain data
        let keyFolder = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")
        let enumerator = FileManager.default.enumerator(at: keyFolder, includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles, .skipsPackageDescendants,
                                                            .skipsSubdirectoryDescendants],
                                                        errorHandler: nil)

        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension == KeyCoverKey.encryptedKeyExtension {
                let keyCover = KeyCoverKey(appBundleID: file.deletingPathExtension().lastPathComponent)
                try? keyCover.decryptKeyFolder()
            }
        }

        // Delete the Master Key
        let masterKeyFile = PlayTools.playCoverContainer.appendingPathComponent("ChainMaster.key")
        try? FileManager.default.removeItem(at: masterKeyFile)
        KeyCover.shared.keyCoverPlainTextKey = nil
        DispatchQueue.main.async {
            KeyCoverObservable.shared.update()
        }
    }
}
