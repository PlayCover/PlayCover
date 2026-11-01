//
//  SourceJSONTests.swift
//  PlayCoverTests
//

import Foundation
import Testing
@testable import PlayCover

struct SourceJSONTests {
    private let appsJSON = """
        [{
            "bundleID": "com.example.app",
            "name": "Example",
            "version": "1.0",
            "itunesLookup": "https://itunes.apple.com/lookup?bundleId=com.example.app",
            "link": "https://example.com/Example.ipa"
        }]
        """

    /// Regression: a publisher's own `id` never matches the user's source entry, so it must not be used.
    @Test func currentFormatKeepsItsNameButTakesTheEntryID() throws {
        let publisherID = UUID()
        let entryID = UUID()
        let json = #"{"name": "My Source", "id": "\#(publisherID.uuidString)", "data": \#(appsJSON)}"#
        let url = try #require(URL(string: "https://example.com/source.json"))

        let source = try SourceJSON.decode(Data(json.utf8), from: url, id: entryID)

        #expect(source.name == "My Source")
        #expect(source.id == entryID)
        #expect(source.data.map(\.bundleID) == ["com.example.app"])
    }

    @Test func currentFormatWithoutAnIDIsAccepted() throws {
        let entryID = UUID()
        let json = #"{"name": "No ID", "data": \#(appsJSON)}"#
        let url = try #require(URL(string: "https://example.com/source.json"))

        let source = try SourceJSON.decode(Data(json.utf8), from: url, id: entryID)

        #expect(source.name == "No ID")
        #expect(source.id == entryID)
    }

    @Test func namesLegacyRemoteSourceAfterHost() throws {
        let id = UUID()
        let url = try #require(URL(string: "https://repo.example.com/apps.json"))

        let source = try SourceJSON.decode(Data(appsJSON.utf8), from: url, id: id)

        #expect(source.name == "repo.example.com")
        #expect(source.id == id)
        #expect(source.data.first?.checksum == nil)
    }

    @Test func namesLegacyLocalSourceAfterFile() throws {
        let url = URL(filePath: "/tmp/apps.json")

        let source = try SourceJSON.decode(Data(appsJSON.utf8), from: url, id: UUID())

        #expect(source.name == "apps")
    }

    @Test func rejectsUnrecognizedDocuments() throws {
        let url = try #require(URL(string: "https://example.com/source.json"))

        #expect(throws: (any Error).self) {
            try SourceJSON.decode(Data(#"{"apps": []}"#.utf8), from: url, id: UUID())
        }
    }
}
