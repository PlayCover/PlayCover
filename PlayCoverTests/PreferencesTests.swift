//
//  PreferencesTests.swift
//  PlayCoverTests
//

import Foundation
import Testing
@testable import PlayCover

@MainActor
struct PreferencesTests {
    private let suiteName = "io.playcover.tests.\(UUID().uuidString)"

    private func makeDefaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: suiteName))
    }

    @Test func installPreferencesDefaults() throws {
        let preferences = InstallPreferences(defaults: try makeDefaults())

        #expect(preferences.alwaysInstallPlayTools)
        #expect(preferences.showInstallPopup == false)
        #expect(preferences.showAppStorePopup)
        #expect(preferences.defaultAppType == .none)
    }

    @Test func installPreferencesPersistUnderTheLegacyKeys() throws {
        let defaults = try makeDefaults()
        let preferences = InstallPreferences(defaults: defaults)
        preferences.alwaysInstallPlayTools = false
        preferences.defaultAppType = .games

        #expect(defaults.bool(forKey: "AlwaysInstallPlayTools") == false)
        #expect(defaults.string(forKey: "DefaultAppType") == LSApplicationCategoryType.games.rawValue)

        let reloaded = InstallPreferences(defaults: defaults)
        #expect(reloaded.alwaysInstallPlayTools == false)
        #expect(reloaded.defaultAppType == .games)
    }

    @Test func uninstallPreferencesRoundTripThroughKeyPaths() throws {
        let defaults = try makeDefaults()
        let preferences = UninstallPreferences(defaults: defaults)
        #expect(preferences.showUninstallPopup)

        for option in UninstallPreferences.cleanupOptions {
            preferences[keyPath: option.keyPath] = true
        }

        let reloaded = UninstallPreferences(defaults: defaults)
        for option in UninstallPreferences.cleanupOptions {
            #expect(reloaded[keyPath: option.keyPath])
        }
        #expect(defaults.bool(forKey: "RemovePlayChainUninstall"))
    }

    @Test func keyCoverPreferencesReadTheStoredStatus() throws {
        let defaults = try makeDefaults()
        defaults.set(KeyCoverStatus.userProvidedPassword.rawValue, forKey: "keyCoverEnabled")

        let preferences = KeyCoverPreferences(defaults: defaults)
        #expect(preferences.keyCoverEnabled == .userProvidedPassword)
        #expect(preferences.promptForKeyCoverPasswordAtLaunch)

        preferences.keyCoverEnabled = .disabled
        #expect(defaults.string(forKey: "keyCoverEnabled") == KeyCoverStatus.disabled.rawValue)
    }
}
