//
//  KeyCover.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import Foundation
import Security

/// On-disk layout of the PlayChain key databases.
nonisolated enum KeyCover {
    static var playChainPath: URL {
        let playChainDir = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")

        if !FileManager.default.fileExists(atPath: playChainDir.path) {
            do {
                try FileManager.default.createDirectory(at: playChainDir, withIntermediateDirectories: true)
            } catch {
                let caught = error
                Task { @MainActor in
                    Log.shared.error(caught)
                }
            }
        }

        return playChainDir
    }

    static func listKeychains() -> [KeyCoverKey] {
        let keychains = (try? FileManager.default
            .contentsOfDirectory(at: playChainPath,
                                 includingPropertiesForKeys: nil,
                                 options: .skipsHiddenFiles)) ?? []
        var seen = Set<String>()
        return keychains.compactMap { file in
            let bundleID = file.deletingPathExtension().lastPathComponent
            return seen.insert(bundleID).inserted ? KeyCoverKey(appBundleID: bundleID) : nil
        }
    }
}

nonisolated struct KeyCoverKey: Sendable, Hashable {
    static let encryptedKeyExtension = "keyCover"
    private static let passwordEnvironmentKey = "PLAYCOVER_KEYCOVER_PASSWORD"

    var appBundleID: String

    var decryptedKeyDB: URL {
        KeyCover.playChainPath
            .appendingPathComponent(appBundleID)
            .appendingPathExtension("db")
    }

    var encryptedKeyDB: URL {
        KeyCover.playChainPath
            .appendingPathComponent(appBundleID)
            .appendingPathExtension(KeyCoverKey.encryptedKeyExtension)
    }

    var chainEncryptionStatus: Bool {
        FileManager.default.fileExists(atPath: encryptedKeyDB.path)
    }

    /// The password reaches openssl through the environment so it never shows up in the process list.
    func encryptKeyDB(password: String) async throws {
        try await Shell.run(print: false, "/usr/bin/openssl",
                            arguments: ["enc", "-aes-256-cbc", "-A",
                                        "-in", decryptedKeyDB.path,
                                        "-out", encryptedKeyDB.path,
                                        "-pass", "env:\(KeyCoverKey.passwordEnvironmentKey)"],
                            environment: [KeyCoverKey.passwordEnvironmentKey: password])
        try deleteKeyDB()
    }

    func decryptKeyDB(password: String) async throws {
        try await Shell.run(print: false, "/usr/bin/openssl",
                            arguments: ["enc", "-aes-256-cbc", "-A", "-d",
                                        "-in", encryptedKeyDB.path,
                                        "-out", decryptedKeyDB.path,
                                        "-pass", "env:\(KeyCoverKey.passwordEnvironmentKey)"],
                            environment: [KeyCoverKey.passwordEnvironmentKey: password])
        try deleteEncryptedKeyDB()
    }

    func deleteKeyDB() throws {
        try FileManager.default.removeItem(at: decryptedKeyDB)
    }

    func deleteEncryptedKeyDB() throws {
        try FileManager.default.removeItem(at: encryptedKeyDB)
    }
}

/// The KeyCover master password in the macOS keychain.
nonisolated enum KeyCoverKeychain {
    private static let tag = "io.playcover.masterkey"

    private static var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: tag,
         kSecAttrAccount as String: tag]
    }

    static func read() -> String? {
        var query = baseQuery
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var dataTypeRef: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &dataTypeRef) == errSecSuccess,
              let data = dataTypeRef as? Data else {
            return nil
        }
        return String(bytes: data, encoding: .utf8)
    }

    static func store(_ password: String) {
        var query = baseQuery
        query[kSecValueData as String] = Data(password.utf8)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error storing master key in keychain: \(status)")
        }
    }

    static func delete() {
        let status = SecItemDelete(baseQuery as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("Error removing master key from keychain: \(status)")
        }
    }

    static func generatePassword() -> String {
        let length = 32
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+"
        return String((0..<length).map { _ in letters.randomElement() ?? "." })
    }
}
