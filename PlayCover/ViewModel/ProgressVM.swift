//
//  ProgressVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 1/13/23.
//

import Foundation

class ProgressVM<Steps: RawRepresentable & Equatable>: ObservableObject where Steps.RawValue == String {
    @Published var progress = 0.0
    @Published var inProgress = false
    @Published var status: Steps

    private let starting: Steps
    private let ends: [Steps]

    /// - Parameters:
    ///     - starts: The initial starting value
    ///     - ends: Ending conditions
    init(start: Steps, ends: [Steps]) {
        self.status = start
        self.starting = start
        self.ends = ends
    }

    func next(_ step: Steps, _ startProgress: Double, _ stopProgress: Double) {
        Task { @MainActor in
            self.progress = startProgress
            self.status = step

            if step == self.starting {
                self.inProgress = true
            } else if self.ends.contains(step) {
                self.progress = 1.0
                try await Task.sleep(nanoseconds: 1500000000)
                self.inProgress = false
            } else {
                while self.status == step {
                    try await Task.sleep(nanoseconds: 50000000)
                    if self.progress < stopProgress {
                        self.progress += 0.002
                    }
                }
            }
        }
    }
}
