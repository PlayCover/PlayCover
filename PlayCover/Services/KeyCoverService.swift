//
//  KeyCoverService.swift
//  PlayCover
//

import Foundation
import Observation

/// Owns the KeyCover master password for the session and encrypts / decrypts PlayChain key databases.
///
/// Launching an app that needs a locked chain suspends on `requestUnlock()` until the user answers the
/// unlock prompt; there is no polling.
@Observable
final class KeyCoverService {
    static var shared: KeyCoverService { AppEnvironment.shared.keyCover }

    @ObservationIgnored private let preferences: KeyCoverPreferences
    @ObservationIgnored private let alerts: AlertPresenter
    @ObservationIgnored private let listKeychains: () -> [KeyCoverKey]

    /// The master password, held only in memory after the user unlocks (or after auto-unlock).
    private(set) var plainTextKey: String?
    private(set) var keychains: [KeyCoverKey] = []
    private(set) var unlockedCount = 0
    private(set) var isUnlockPromptShown: Bool

    @ObservationIgnored private var unlockWaiters: [CheckedContinuation<Void, Never>] = []
    /// Apps that launched without their chain because the user declined to unlock.
    @ObservationIgnored private var sessionDisabledApps: Set<String> = []

    init(preferences: KeyCoverPreferences, alerts: AlertPresenter,
         listKeychains: @escaping () -> [KeyCoverKey] = KeyCover.listKeychains) {
        self.preferences = preferences
        self.alerts = alerts
        self.listKeychains = listKeychains
        if preferences.keyCoverEnabled == .selfGeneratedPassword {
            plainTextKey = KeyCoverKeychain.read()
        }
        isUnlockPromptShown = preferences.keyCoverEnabled == .userProvidedPassword
            && preferences.promptForKeyCoverPasswordAtLaunch
        refresh()
    }

    var isEnabled: Bool { preferences.keyCoverEnabled != .disabled }

    func refresh() {
        keychains = listKeychains()
        unlockedCount = keychains.filter { !$0.chainEncryptionStatus }.count
    }

    // MARK: - Unlock prompt

    /// Suspends until the user unlocks or dismisses the prompt. Returns immediately when already unlocked.
    func requestUnlock() async {
        guard plainTextKey == nil else { return }
        isUnlockPromptShown = true
        await withCheckedContinuation { unlockWaiters.append($0) }
    }

    /// Validates `password` against the keychain; on success keeps it for the session and closes the prompt.
    func submitUnlock(password: String) -> Bool {
        guard validatePassword(password) else { return false }
        plainTextKey = password
        dismissUnlockPrompt()
        return true
    }

    func dismissUnlockPrompt() {
        isUnlockPromptShown = false
        let waiters = unlockWaiters
        unlockWaiters.removeAll()
        waiters.forEach { $0.resume() }
    }

    // MARK: - Chains

    func unlockChain(_ keychain: KeyCoverKey) async throws {
        await requestUnlock()
        guard let password = plainTextKey, keychain.chainEncryptionStatus else { return }
        try await keychain.decryptKeyDB(password: password)
        refresh()
    }

    func lockChain(_ keychain: KeyCoverKey) async throws {
        guard let password = plainTextKey, !keychain.chainEncryptionStatus else { return }
        try await keychain.encryptKeyDB(password: password)
        refresh()
    }

    func lockAllChains() async {
        guard let password = plainTextKey else { return }
        for keychain in listKeychains() where !keychain.chainEncryptionStatus {
            try? await keychain.encryptKeyDB(password: password)
        }
        refresh()
    }

    /// Decrypts the app's chain before launch. If the user declines, the app runs without PlayChain
    /// for this session and the setting is restored when it quits.
    func unlock(for app: PlayApp) async {
        guard isEnabled,
              let keychain = keychain(for: app),
              keychain.chainEncryptionStatus else { return }

        try? await unlockChain(keychain)

        if plainTextKey == nil {
            await alerts.present(AlertRequest(
                title: NSLocalizedString("keycover.alert.title", comment: ""),
                message: NSLocalizedString("keycover.alert.content", comment: ""),
                style: .warning
            ))
            app.settings.settings.playChain = false
            sessionDisabledApps.insert(app.info.bundleIdentifier)
        }
    }

    /// Re-encrypts the app's chain once it quits.
    func lock(for app: PlayApp) async {
        guard isEnabled else { return }
        if sessionDisabledApps.remove(app.info.bundleIdentifier) != nil {
            app.settings.settings.playChain = true
            return
        }
        if let keychain = keychain(for: app) {
            try? await lockChain(keychain)
        }
    }

    private func keychain(for app: PlayApp) -> KeyCoverKey? {
        listKeychains().first { $0.appBundleID == app.info.bundleIdentifier }
    }

    // MARK: - Master password

    func validatePassword(_ key: String) -> Bool {
        key == KeyCoverKeychain.read()
    }

    func generateVerySecurePassword() -> String {
        KeyCoverKeychain.generatePassword()
    }

    /// Replaces the master password and re-encrypts every chain with it.
    func setPassword(_ key: String, status: KeyCoverStatus) async {
        if let oldKey = KeyCoverKeychain.read() {
            for keychain in listKeychains() where keychain.chainEncryptionStatus {
                try? await keychain.decryptKeyDB(password: oldKey)
            }
            KeyCoverKeychain.delete()
        }

        KeyCoverKeychain.store(key)
        preferences.keyCoverEnabled = status
        plainTextKey = key

        for keychain in listKeychains() where !keychain.chainEncryptionStatus {
            try? await keychain.encryptKeyDB(password: key)
        }
        refresh()
    }

    /// Decrypts every chain and turns KeyCover off.
    func removePassword() async {
        if let key = KeyCoverKeychain.read() {
            for chain in listKeychains() where chain.chainEncryptionStatus {
                try? await chain.decryptKeyDB(password: key)
            }
        }
        KeyCoverKeychain.delete()
        preferences.keyCoverEnabled = .disabled
        plainTextKey = nil
        refresh()
    }

    /// Forgotten password: the encrypted chains are useless, so they are deleted.
    func forceResetPassword() {
        // A key in memory means the user can still decrypt; refuse to destroy data.
        guard plainTextKey == nil else { return }
        KeyCoverKeychain.delete()
        preferences.keyCoverEnabled = .disabled
        for chain in listKeychains() {
            try? chain.deleteEncryptedKeyDB()
        }
        refresh()
    }
}
