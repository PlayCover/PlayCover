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
    @Published var installing  = false

    static let shared = InstallVM()

    func next(_ step: InstallStepsNative) {
        DispatchQueue.main.async {
            self.progress = 0
            self.status = NSLocalizedString(step.rawValue, comment: "")
        }

        if step == .begin {

            DispatchQueue.main.async {
                self.progress = 0
                self.installing = true

                DispatchQueue.global(qos: .userInitiated).async {
                    while self.installing == true {
                        usleep(100000)
                        DispatchQueue.main.async {
                            if self.progress < 100 {
                                self.progress += 0.01
                            } else {
                                self.progress = 0
                            }
                        }
                    }
                }

            }

        }

        if step == .finish {
            DispatchQueue.main.async {
                self.installing = false
            }
        }
    }

}
