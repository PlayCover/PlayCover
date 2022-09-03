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
         finish = "playapp.install.finished"
}

class InstallVM: ObservableObject {

    @Published var status: String = NSLocalizedString(InstallStepsNative.begin.rawValue, comment: "")
    @Published var progress = 0.0
    @Published var installing = false

    static let shared = InstallVM()

    func next(_ step: InstallStepsNative, _ startProgress: Double, _ stopProgress: Double) {
        DispatchQueue.main.async {
            self.progress = startProgress
            self.status = NSLocalizedString(step.rawValue, comment: "")
            if step == .begin {
                self.installing = true
            } else if step == .finish {
                self.progress = 1.0
                DispatchQueue.global(qos: .userInteractive).async {
                    usleep(1500000)
                    DispatchQueue.main.async {
                        self.installing = false
                    }
                }
            }
            DispatchQueue.global(qos: .userInitiated).async {
                while self.status == NSLocalizedString(step.rawValue, comment: "") {
                    usleep(50000)
                    DispatchQueue.main.async {
                        if self.progress < stopProgress {
                            self.progress += 0.002
                        }
                    }
                }
            }
        }
    }
}
