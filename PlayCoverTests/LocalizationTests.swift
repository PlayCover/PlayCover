//
//  LocalizationTests.swift
//  PlayCoverTests
//

import Foundation
import Testing
@testable import PlayCover

/// A key missing from a table is shown to users as the raw key, so every localization must carry
/// every English key (an English fallback is acceptable until someone translates it).
struct LocalizationTests {
    nonisolated private static let bundle = Bundle(for: AppEnvironment.self)

    // Read while building the test list, outside any actor.
    nonisolated private static var localizations: [String] {
        bundle.localizations.filter { $0 != "Base" }
    }

    private static func table(_ localization: String) throws -> [String: String] {
        let url = try #require(bundle.url(forResource: "Localizable", withExtension: "strings",
                                          subdirectory: nil, localization: localization))
        return try #require(NSDictionary(contentsOf: url) as? [String: String])
    }

    private static func keys(_ localization: String) throws -> Set<String> {
        Set(try table(localization).keys)
    }

    @Test func appShipsSeveralLocalizations() {
        #expect(Self.localizations.contains("en"))
        #expect(Self.localizations.contains("zh-Hans"))
    }

    @Test(arguments: localizations)
    func everyEnglishKeyIsPresent(_ localization: String) throws {
        let missing = try Self.keys("en").subtracting(Self.keys(localization))
        #expect(missing.isEmpty, "\(localization) is missing \(missing.sorted())")
    }

    /// Category names are looked up by their raw identifier, so each one needs an English entry.
    @Test func everyAppCategoryHasAName() throws {
        let english = try Self.table("en")
        for category in LSApplicationCategoryType.allCases {
            #expect(english[category.rawValue] != nil, "missing name for \(category.rawValue)")
        }
    }

    @Test(arguments: ["zh-Hans", "zh-Hant"])
    func chineseHasRealTranslationsForRecentSettings(_ localization: String) throws {
        let english = try Self.table("en")
        let chinese = try Self.table(localization)
        for key in ["playapp.keymap", "settings.toggle.disableBuiltinMouse", "settings.customPlugins.title"] {
            #expect(chinese[key] != nil)
            #expect(chinese[key] != english[key], "\(localization) still uses English for \(key)")
        }
    }
}
