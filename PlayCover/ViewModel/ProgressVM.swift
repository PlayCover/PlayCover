//
//  ProgressVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 1/13/23.
//

import Foundation
import SwiftUI

typealias Cancel = (() -> Void)?

class ProgressVM<Steps: RawRepresentable & Equatable>: ObservableObject where Steps.RawValue == String {
    @Published var progress = 0.0
    @Published var inProgress = false
    @Published var status: Steps
    @Published var isCollapsed = false
    @Published var name: String = ""

    internal let starting: Steps
    internal let ends: [Steps]
    internal let cancelableSteps: [Steps]?
    internal var cancelFunc: Cancel

    /// - Parameters:
    ///     - starts: The initial starting value
    ///     - ends: Ending conditions
    ///     - cancelableSteps: Steps that are allowed to be canceled
    ///     - cancel: The function that runs when the canceller has been called
    init(start: Steps, ends: [Steps], cancelableSteps: [Steps]? = nil, cancel: Cancel = nil) {
        self.status = start
        self.starting = start
        self.ends = ends
        self.cancelableSteps = cancelableSteps
        self.cancelFunc = cancel
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

                // Ensure another download isn't already in progress
                guard self.progress == 1.0 else {
                    return
                }

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

    func constructView(collapsable: Bool = true) -> some View {
        return
            VStack {
                if !isCollapsed || !collapsable {
                    Text(NSLocalizedString(status.rawValue, comment: "")) +
                    Text(!name.isEmpty ? " " + name : "")
                }
                HStack {
                    ProgressView(value: self.progress)
                    if let cancels = cancelableSteps, cancels.contains(self.status) {
                        Button {
                            self.cancelFunc?()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                }

            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .padding()
            .onTapGesture {
                if collapsable {
                    self.isCollapsed.toggle()
                }
            }
    }
}
