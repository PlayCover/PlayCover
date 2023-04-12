//
//  KeyCover.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import Foundation
import CryptoKit
import SwiftUI
import Security

struct KeyCover {
    static var shared = KeyCover()

    // This is only exposed at runtime
    var keyCoverPlainTextKey: String? = KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword
    ? KeyCoverPassword.shared.getKeyCoverPassword() : nil

    func isKeyCoverEnabled() -> Bool {
        return KeyCoverPreferences.shared.keyCoverEnabled != .disabled
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

    func unlockChain(_ keychain: KeyCoverKey) async throws {
        if keyCoverPlainTextKey == nil {
            let task = Task {@MainActor in
                KeyCoverObservable.shared.isKeyCoverUnlockingPromptShown = true
            }
            await task.value
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
        Task {
            for keychain in KeyCover.shared.listKeychains() where !keychain.chainEncryptionStatus {
                try? keychain.encryptKeyFolder()
            }
        }
    }
}

class KeyCoverObservable: ObservableObject {
    static var shared = KeyCoverObservable()

    @Published var keyCoverEnabled = KeyCover.shared.isKeyCoverEnabled()
    @Published var unlockedCount = KeyCover.shared.unlockedCount()
    @Published var keychains = KeyCover.shared.listKeychains()

    @Published var isKeyCoverUnlockingPromptShown = KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword
    ? false : KeyCoverPreferences.shared.keyCoverEnabled == .disabled
    ? false : KeyCoverPreferences.shared.promptForKeyCoverPasswordAtLaunch

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
        if let plainTextKey = KeyCover.shared.keyCoverPlainTextKey {
            // zip up the key folder
            // make sure to only compress the key folder, not the entire path to it
            let source = keyFolderPath.appendingPathComponent(appBundleID)
            let destination = keyFolderPath.appendingPathComponent("\(appBundleID).zip")
            let task = Process()
            task.launchPath = "/usr/bin/zip"
            task.currentDirectoryPath = keyFolderPath.path
            task.arguments = ["-q", "-r", destination.path, source.lastPathComponent]
            task.launch()
            task.waitUntilExit()

            // encrypt the zip file
            let task2 = Process()
            task2.launchPath = "/usr/bin/openssl"
            task2.currentDirectoryPath = keyFolderPath.path
            task2.arguments = ["enc", "-aes-256-cbc", "-A",
                                "-in", destination.path,
                                "-out", encryptedKeyFile.path,
                                "-k", plainTextKey]
            task2.launch()
            task2.waitUntilExit()

            // delete the zip file
            try? FileManager.default.removeItem(at: destination)

            // delete the key folder
            try? deleteKeyFolder()

            Task { @MainActor in
                KeyCoverObservable.shared.update()
            }
        }
    }

    func decryptKeyFolder() throws {
        if let plainTextKey = KeyCover.shared.keyCoverPlainTextKey {
            // decrypt the zip file
            let task = Process()
            task.launchPath = "/usr/bin/openssl"
            task.arguments = ["enc", "-aes-256-cbc", "-A", "-d", "-in", encryptedKeyFile.path, "-out",
                              keyFolderPath.appendingPathComponent("\(appBundleID).zip").path,
                              "-k", plainTextKey]
            task.launch()
            task.waitUntilExit()

            // unzip the zip file
            let task2 = Process()
            task2.launchPath = "/usr/bin/unzip"
            task2.currentDirectoryPath = keyFolderPath.path
            task2.arguments = ["-qq", "-o", keyFolderPath.appendingPathComponent("\(appBundleID).zip").path,
                               "-d", keyFolderPath.path]
            task2.launch()
            task2.waitUntilExit()

            // delete the zip file
            try? FileManager.default.removeItem(at: keyFolderPath.appendingPathComponent("\(appBundleID).zip"))

            // delete the encrypted key file
            try? FileManager.default.removeItem(at: encryptedKeyFile)

            Task { @MainActor in
                KeyCoverObservable.shared.update()
            }
        }
    }

    func deleteKeyFolder() throws {
        try? FileManager.default.removeItem(at: keyFolderPath.appendingPathComponent(appBundleID))
    }

    func wipeEncryptedKeyFile() throws {
        try? FileManager.default.removeItem(at: encryptedKeyFile)
    }
}

class KeyCoverPassword {
    static let shared = KeyCoverPassword()

    let tag = "io.playcover.masterkey"

    func setKeyCoverPassword(_ key: String) {
        // swiftlint: disable force_unwrapping
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: tag,
                                    kSecAttrAccount as String: tag,
                                    kSecValueData as String: key.data(using: .utf8)!]
        // swiftlint: enable force_unwrapping
        // thank you apple very cool
        // Get the key
        let oldKey = getKeyCoverPassword()
        // if it is not nil, then we need to decrypt all the keychains
        if oldKey != nil {
            KeyCover.shared.keyCoverPlainTextKey = oldKey
            for keychain in KeyCover.shared.listKeychains() where keychain.chainEncryptionStatus {
                try? keychain.decryptKeyFolder()
            }
            KeyCover.shared.keyCoverPlainTextKey = nil
            // Remove any existing master key
            SecItemDelete(query as CFDictionary)
        }

        // Store the master key in macOS keychain
        Task(priority: .userInitiated) {
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                print("Error storing master key in keychain: \(status)")
            }
        }

        KeyCover.shared.keyCoverPlainTextKey = key

        // Encrypts all keychains
        for keychain in KeyCover.shared.listKeychains() where !keychain.chainEncryptionStatus {
            try? keychain.encryptKeyFolder()
        }

        Task { @MainActor in
            KeyCoverObservable.shared.update()
        }
    }

    func getKeyCoverPassword() -> String? {
        // Get the master key from macOS keychain
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: tag,
                                    kSecAttrAccount as String: tag,
                                    kSecReturnData as String: kCFBooleanTrue as Any,
                                    kSecMatchLimit as String: kSecMatchLimitOne]

        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data {
                return String(data: data, encoding: .utf8)
            }
        }
        return nil
    }

    func removeKeyCoverPassword() {
        // Decrypt all key folders
        for chain in KeyCover.shared.listKeychains() where chain.chainEncryptionStatus {
                try? chain.decryptKeyFolder()
        }

        // Remove the master key from macOS keychain
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: tag,
                                    kSecAttrAccount as String: tag]

        Task(priority: .userInitiated) {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess {
                print("Error removing master key from keychain: \(status)")
            }
        }

        KeyCoverPreferences.shared.keyCoverEnabled = .disabled
        KeyCover.shared.keyCoverPlainTextKey = nil

        Task { @MainActor in
            KeyCoverObservable.shared.update()
        }
    }

    func forceResetKeyCoverPassword() {
        // If a key is in memory, don't do anything (prevent accidental deletion)
        if KeyCover.shared.keyCoverPlainTextKey != nil {
            return
        }
        // Remove the master key from macOS keychain
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: tag,
                                    kSecAttrAccount as String: tag]

        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("Error removing master key from keychain: \(status)")
        }

        KeyCoverPreferences.shared.keyCoverEnabled = .disabled
        KeyCover.shared.keyCoverPlainTextKey = nil

        // Being a force reset, we have to nuke everything (because it's useless otherwise)
        for chain in KeyCover.shared.listKeychains() {
            try? chain.wipeEncryptedKeyFile()
        }

        Task { @MainActor in
            KeyCoverObservable.shared.update()
        }
    }

    func validatePassword(_ key: String) -> Bool {
        return key == getKeyCoverPassword()
    }

    func generateVerySecurePassword() -> String {
        // oh my god
        let length = 32
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+"
        return String((0..<length).map { _ in letters.randomElement() ?? "." })
    }
}
