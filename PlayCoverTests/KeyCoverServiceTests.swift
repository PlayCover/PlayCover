//
//  KeyCoverServiceTests.swift
//  PlayCoverTests
//

import Foundation
import Testing
@testable import PlayCover

@MainActor
struct KeyCoverServiceTests {
    private func makeService(status: KeyCoverStatus, promptAtLaunch: Bool) throws -> KeyCoverService {
        let defaults = try #require(UserDefaults(suiteName: "io.playcover.tests.\(UUID().uuidString)"))
        defaults.set(status.rawValue, forKey: "keyCoverEnabled")
        defaults.set(promptAtLaunch, forKey: "promptForKeyCoverPasswordAtLaunch")
        return KeyCoverService(preferences: KeyCoverPreferences(defaults: defaults),
                               alerts: AlertPresenter(),
                               listKeychains: { [] })
    }

    @Test func launchPromptFollowsPreferences() throws {
        #expect(try makeService(status: .userProvidedPassword, promptAtLaunch: true).isUnlockPromptShown)
        #expect(try makeService(status: .userProvidedPassword, promptAtLaunch: false).isUnlockPromptShown == false)
        #expect(try makeService(status: .disabled, promptAtLaunch: true).isUnlockPromptShown == false)
    }

    @Test func requestUnlockWaitsForThePromptToClose() async throws {
        let service = try makeService(status: .userProvidedPassword, promptAtLaunch: false)

        let firstWaiter = Task { await service.requestUnlock() }
        let secondWaiter = Task { await service.requestUnlock() }
        for _ in 0..<50 where !service.isUnlockPromptShown {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(service.isUnlockPromptShown)

        service.dismissUnlockPrompt()
        await firstWaiter.value
        await secondWaiter.value

        #expect(service.isUnlockPromptShown == false)
        #expect(service.plainTextKey == nil)
    }

    @Test func refreshCountsUnlockedChains() throws {
        let service = try makeService(status: .disabled, promptAtLaunch: false)
        #expect(service.keychains.isEmpty)
        #expect(service.unlockedCount == 0)
        #expect(service.isEnabled == false)
    }
}
