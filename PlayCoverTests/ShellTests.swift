//
//  ShellTests.swift
//  PlayCoverTests
//

import Foundation
import Testing
@testable import PlayCover

struct ShellTests {
    @Test func returnsCombinedOutput() async throws {
        let output = try await Shell.run(print: false, "/bin/echo", "hello", "world")
        #expect(output == "hello world\n")
    }

    @Test func nonZeroExitThrowsTheOutput() async {
        await #expect(throws: (any Error).self) {
            try await Shell.run(print: false, "/bin/sh", "-c", "echo failure >&2; exit 3")
        }
    }

    @Test func passesExtraEnvironment() async throws {
        let output = try await Shell.run(print: false, "/usr/bin/printenv",
                                         arguments: ["PLAYCOVER_TEST_VALUE"],
                                         environment: ["PLAYCOVER_TEST_VALUE": "secret"])
        #expect(output == "secret\n")
    }

    /// More output than a pipe buffer holds must not stall the child.
    @Test func drainsLargeOutput() async throws {
        let output = try await Shell.run(print: false, "/bin/sh", "-c", "yes x | head -c 200000")
        #expect(output.utf8.count == 200_000)
    }

    @Test func verifySignatureIsFalseForUnsignedPath() async {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        #expect(await Shell.verifySignature(missing) == false)
    }
}
