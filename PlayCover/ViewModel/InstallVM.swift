//
//  InstallSteps.swift
//  PlayCover
//

import Foundation

enum InstallStepsNative: String {
    case unzip = "app.install.unzip",
         wrapper = "app.install.createWrapper",
         playtools = "app.install.installPlayTools",
         sign = "app.install.signing",
         library = "app.install.addToLib",
         begin = "app.install.copy",
         finish = "app.install.finished"
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
