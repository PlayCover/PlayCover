//
//  ProgressVMTests.swift
//  PlayCoverTests
//

import Foundation
import Testing
@testable import PlayCover

@MainActor
struct ProgressVMTests {
    @Test func startingStepMarksInProgress() {
        let progress = InstallVM()
        progress.next(.begin, 0.0, 0.0)

        #expect(progress.inProgress)
        #expect(progress.status == .begin)
        #expect(progress.progress == 0.0)
    }

    @Test func intermediateStepCreepsTowardItsUpperBound() async throws {
        let progress = InstallVM()
        progress.next(.begin, 0.0, 0.0)
        progress.next(.unzip, 0.4, 0.41)

        #expect(progress.status == .unzip)
        #expect(progress.progress == 0.4)
        try await Task.sleep(for: .milliseconds(600))
        #expect(progress.progress > 0.4)
        #expect(progress.progress <= 0.41)
        #expect(progress.inProgress)
    }

    /// Regression: the bar must read 1.0 the moment a job ends, even while the previous step is easing.
    @Test func endingStepWinsOverAnInFlightEase() async throws {
        let progress = InstallVM()
        progress.next(.begin, 0.0, 0.0)
        progress.next(.wrapper, 0.85, 0.95)
        try await Task.sleep(for: .milliseconds(120))
        progress.next(.finish, 0.95, 1.0)

        #expect(progress.progress == 1.0)
        try await Task.sleep(for: .milliseconds(200))
        #expect(progress.progress == 1.0)
    }

    @Test func endingStepFillsTheBarThenClearsInProgress() async throws {
        let progress = InstallVM()
        progress.next(.begin, 0.0, 0.0)
        progress.next(.finish, 0.95, 1.0)

        #expect(progress.progress == 1.0)
        #expect(progress.inProgress)

        try await Task.sleep(for: .milliseconds(1700))
        #expect(progress.inProgress == false)
    }

    @Test func reportOverridesTheEstimate() {
        let progress = DownloadVM()
        progress.next(.downloading, 0.0, 0.7)
        progress.report(0.25)

        #expect(progress.progress == 0.25)
        #expect(progress.status == .downloading)
    }

    @Test func tracksUpdatesFromAStream() async throws {
        let progress = InstallVM()
        let (updates, continuation) = AsyncStream.makeStream(of: InstallVM.Update.self)
        progress.track(updates)

        continuation.yield(.init(.begin, 0.0, 0.0))
        continuation.yield(.init(.playtools, 0.55, 0.85))
        continuation.finish()

        for _ in 0..<50 where progress.status != .playtools {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(progress.status == .playtools)
        #expect(progress.inProgress)
    }
}
