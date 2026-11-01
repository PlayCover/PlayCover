//
//  ProgressVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 1/13/23.
//

import Observation

/// Step-based progress for long jobs (install, download).
///
/// Services push `Update`s through an `AsyncStream`; the view model applies them on the main actor.
/// Between updates the bar creeps toward the step's upper bound. Each step owns one easing task that the
/// next update cancels, so a finished or failed job always shows its final value immediately.
/// (A SwiftUI animation cannot do this: animations are additive, and an in-flight one keeps pulling the
/// bar back after the value jumps to 1.0.)
nonisolated struct ProgressUpdate<Steps: Sendable>: Sendable {
    let step: Steps
    let startProgress: Double
    let stopProgress: Double

    init(_ step: Steps, _ startProgress: Double, _ stopProgress: Double) {
        self.step = step
        self.startProgress = startProgress
        self.stopProgress = stopProgress
    }
}

@Observable
class ProgressVM<Steps: RawRepresentable & Equatable & Sendable> where Steps.RawValue == String {
    typealias Update = ProgressUpdate<Steps>

    private static var easingInterval: Duration { .milliseconds(50) }
    private static var easingIncrement: Double { 0.002 }
    private static var finishedLinger: Duration { .milliseconds(1500) }

    var progress = 0.0
    var inProgress = false
    var status: Steps

    @ObservationIgnored private let starting: Steps
    @ObservationIgnored private let ends: [Steps]
    @ObservationIgnored private var trackingTask: Task<Void, Never>?
    @ObservationIgnored private var lingerTask: Task<Void, Never>?
    @ObservationIgnored private var easingTask: Task<Void, Never>?

    /// - Parameters:
    ///     - starts: The initial starting value
    ///     - ends: Ending conditions
    init(start: Steps, ends: [Steps]) {
        self.status = start
        self.starting = start
        self.ends = ends
    }

    /// Applies every update from `updates` until the stream finishes.
    func track(_ updates: AsyncStream<Update>) {
        trackingTask?.cancel()
        trackingTask = Task { [weak self] in
            for await update in updates {
                self?.apply(update)
            }
        }
    }

    func next(_ step: Steps, _ startProgress: Double, _ stopProgress: Double) {
        apply(Update(step, startProgress, stopProgress))
    }

    /// Sets a measured value (e.g. bytes downloaded) without the estimated easing.
    func report(_ value: Double) {
        easingTask?.cancel()
        progress = value
    }

    private func apply(_ update: Update) {
        lingerTask?.cancel()
        report(update.startProgress)
        status = update.step

        if update.step == starting {
            inProgress = true
        } else if ends.contains(update.step) {
            progress = 1.0
            lingerTask = Task { [weak self] in
                guard (try? await Task.sleep(for: Self.finishedLinger)) != nil else { return }
                self?.inProgress = false
            }
        } else if update.stopProgress > update.startProgress {
            let target = update.stopProgress
            easingTask = Task { [weak self] in
                while (try? await Task.sleep(for: Self.easingInterval)) != nil {
                    guard let self, self.progress < target else { return }
                    self.progress = min(target, self.progress + Self.easingIncrement)
                }
            }
        }
    }
}
