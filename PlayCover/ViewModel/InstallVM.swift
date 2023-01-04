//
//  InstallSteps.swift
//  PlayCover
//

import Foundation

enum InstallStepsNative: String {
    case unzip = "playapp.install.unzip",
         wrapper = "playapp.install.createWrapper",
         playtools = "playapp.install.installPlayTools",
         sign = "playapp.install.signing",
         library = "playapp.install.addToLib",
         begin = "playapp.install.copy",
         finish = "playapp.install.finished",
         failed = "playapp.install.failed"
}

class InstallVM: ObservableObject {

    @Published var status: String = NSLocalizedString(InstallStepsNative.begin.rawValue, comment: "")
    @Published var progress = 0.0
    @Published var installing = false

    static let shared = InstallVM()

    func next(_ step: InstallStepsNative, _ startProgress: Double, _ stopProgress: Double) {
        Task { @MainActor in
            self.progress = startProgress
            self.status = NSLocalizedString(step.rawValue, comment: "")
            if step == .begin {
                self.installing = true
            } else if step == .finish || step == .failed {
                self.progress = 1.0
                try await Task.sleep(nanoseconds: 1500000000)
                self.installing = false
            }
            while self.status == NSLocalizedString(step.rawValue, comment: "") {
                try await Task.sleep(nanoseconds: 50000000)
                if self.progress < stopProgress {
                    self.progress += 0.002
                }
            }
        }
    }
}
