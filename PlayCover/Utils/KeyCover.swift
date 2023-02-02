//
//  KeyCover.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import Foundation
import CryptoKit

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
        if keyCoverPlainTextKey == nil {
            return []
        }
        // Enumerate all the keychains
        let keychains = try? FileManager.default
            .contentsOfDirectory(at: PlayTools.playCoverContainer.appendingPathComponent("PlayChain"),
                                 includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        var keychainList: [KeyCoverKey] = []
        for keychain in keychains ?? [] {
            let keychainName = keychain.lastPathComponent
            let keychainPath = keychain.appendingPathComponent(keychainName)
            if FileManager.default.fileExists(atPath: keychainPath.path) {
                let keychain = KeyCoverKey(appBundleID: keychainName)
                keychainList.append(keychain)
            }
        }
        return keychainList
    }

    func unlockedCount() -> Int  {
        var count = 0
        for keychain in listKeychains() where !keychain.chainEncryptionStatus {
            count += 1
        }
        return count
    }

    func unlockChain(_ keychain: KeyCoverKey) throws {
        if keyCoverPlainTextKey == nil {
            // Open the unlocking window and wait for the user to enter the password
            // Then set the keyCoverPlainTextKey
            _ = KeyCoverUnlockingPrompt.openWindow()
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
        let source = keyFolderPath.appendingPathComponent(appBundleID)
        let destination = keyFolderPath.appendingPathComponent("\(appBundleID).zip")
        let task = Process()
        task.launchPath = "/usr/bin/zip"
        task.arguments = ["-r", destination.path, source.path]
        task.launch()

        // encrypt the zip file
        let task2 = Process()
        task2.launchPath = "/usr/bin/openssl"
        task2.arguments = ["enc", "-aes-256-cbc", "-A",
                           "-in", destination.path,
                           "-out", encryptedKeyFile.path,
                           "-k", KeyCover.shared.keyCoverPlainTextKey!]
        task2.launch()

        // delete the zip file
        try? FileManager.default.removeItem(at: destination)

        // delete the key folder
        try? deleteKeyFolder()
    }

    func decryptKeyFolder() throws {
        // decrypt the zip file
        let task = Process()
        task.launchPath = "/usr/bin/openssl"
        task.arguments = ["enc", "-aes-256-cbc", "-A", "-d", "-in", encryptedKeyFile.path, "-out",
                          keyFolderPath.appendingPathComponent("\(appBundleID).zip").path,
                          "-k", KeyCover.shared.keyCoverPlainTextKey!]
        task.launch()

        // unzip the zip file
        let task2 = Process()
        task2.launchPath = "/usr/bin/unzip"
        task2.arguments = [keyFolderPath.appendingPathComponent("\(appBundleID).zip").path, "-d", keyFolderPath.path]
        task2.launch()

        // delete the zip file
        try? FileManager.default.removeItem(at: keyFolderPath.appendingPathComponent("\(appBundleID).zip"))
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
        // if the key file does exist, keys will automatically be re-encrypted by updateMasterKey()
        // so just set new key and move on
        if keyExists {
            let hashedKey = hashKey(key)
            try? hashedKey.write(to: masterKeyFile, atomically: true, encoding: .utf8)
            return
        }

        // if the key file does not exist, we need to perform an initial encryption round
        // set the new master key
        let hashedKey = hashKey(key)
        try? hashedKey.write(to: masterKeyFile, atomically: true, encoding: .utf8)

        // enumerate the file in the key folder
        let keyFolder = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")
        let enumerator = FileManager.default.enumerator(at: keyFolder, includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles,
                                                                  .skipsPackageDescendants,
                                                                  .skipsSubdirectoryDescendants],
                                                        errorHandler: nil)

        // encrypt each key folder
        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension == KeyCoverKey.encryptedKeyExtension {
                let keyCover = KeyCoverKey(appBundleID: file.deletingPathExtension().lastPathComponent)
                try? keyCover.encryptKeyFolder()
            }
        }
    }

    static func updateMasterKey(_ key: String) {
        // enumerate the file in the key folder
        let keyFolder = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")
        let enumerator = FileManager.default.enumerator(at: keyFolder, includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles, .skipsPackageDescendants,
                                                            .skipsSubdirectoryDescendants],
                                                        errorHandler: nil)

        // decrypt each key file
        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension == KeyCoverKey.encryptedKeyExtension {
                let keyCover = KeyCoverKey(appBundleID: file.deletingPathExtension().lastPathComponent)
                try? keyCover.decryptKeyFolder()
            }
        }

        // set the new master key
        setMasterKey(key)

        // encrypt each key file
        while let file = enumerator?.nextObject() as? URL {
            if file.pathExtension == KeyCoverKey.encryptedKeyExtension {
                let keyCover = KeyCoverKey(appBundleID: file.deletingPathExtension().lastPathComponent)
                try? keyCover.encryptKeyFolder()
            }
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
    }
}
