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
         finish = "playapp.progress.finished",
         failed = "playapp.progress.failed"
}

class InstallVM: ProgressVM<InstallStepsNative> {

    static let shared = InstallVM()

    init() {
        super.init(start: .begin, ends: [.finish, .failed])
    }

}
