//
//  AppSettingsDataTests.swift
//  PlayCoverTests
//

import Foundation
import Testing
@testable import PlayCover

struct AppSettingsDataTests {
    @Test func missingKeysFallBackToDefaults() throws {
        let settings = try decode([:])

        #expect(settings.bundleIdentifier == "")
        #expect(settings.keymapping)
        #expect(settings.sensitivity == 50)
        #expect(settings.iosDeviceModel == "iPad13,8")
        #expect(settings.windowWidth == 1920)
        #expect(settings.windowHeight == 1080)
        #expect(settings.version == "3.0.0")
        #expect(settings.playChain)
        #expect(settings.rootWorkDir)
        #expect(settings.metalHUD == false)
        #expect(settings.overrideFullScreen == false)
        #expect(settings.stashedRequiresFullScreen == nil)
        #expect(settings.stashedIpadOrientations == nil)
    }

    @Test func legacySettingsKeepStoredValuesAndGainNewDefaults() throws {
        let settings = try decode([
            "bundleIdentifier": "com.example.game",
            "keymapping": false,
            "sensitivity": 75.0,
            "windowWidth": 2560,
            "version": "2.0.0"
        ])

        #expect(settings.bundleIdentifier == "com.example.game")
        #expect(settings.keymapping == false)
        #expect(settings.sensitivity == 75)
        #expect(settings.windowWidth == 2560)
        #expect(settings.version == "2.0.0")
        // PlayChain did not exist in 2.x settings.
        #expect(settings.playChain)
    }

    /// Every stored key is changed away from its default, so a field that is encoded but not decoded
    /// (or the other way round) shows up as a mismatch.
    @Test func everyEncodedFieldSurvivesARoundTrip() throws {
        var plist = try encodedDictionary(AppSettingsData())
        for (key, value) in plist {
            plist[key] = changed(value)
        }
        plist["stashedRequiresFullScreen"] = true
        plist["stashedIpadOrientations"] = ["UIInterfaceOrientationPortrait"]

        let roundTripped = try encodedDictionary(try decode(plist))

        #expect(NSDictionary(dictionary: roundTripped) == NSDictionary(dictionary: plist))
    }

    private func decode(_ plist: [String: Any]) throws -> AppSettingsData {
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        return try PropertyListDecoder().decode(AppSettingsData.self, from: data)
    }

    private func encodedDictionary(_ settings: AppSettingsData) throws -> [String: Any] {
        let data = try PropertyListEncoder().encode(settings)
        return try #require(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    private func changed(_ value: Any) -> Any {
        switch value {
        case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID():
            return !number.boolValue
        case let number as NSNumber where CFNumberIsFloatType(number):
            return number.doubleValue + 1.5
        case let number as NSNumber:
            return number.intValue + 1
        case let string as String:
            return string + "-changed"
        default:
            return value
        }
    }
}
