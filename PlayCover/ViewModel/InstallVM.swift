//
//  InstallSteps.swift
//  PlayCover
//

import Foundation

nonisolated enum InstallStepsNative: String, Sendable {
    case unzip = "playapp.install.unzip",
         wrapper = "playapp.install.createWrapper",
         playtools = "playapp.install.installPlayTools",
         sign = "playapp.install.signing",
         library = "playapp.install.addToLib",
         begin = "playapp.install.copy",
         finish = "playapp.progress.finished",
         failed = "playapp.progress.failed"
}

final class InstallVM: ProgressVM<InstallStepsNative> {

    static var shared: InstallVM { AppEnvironment.shared.install }

    init() {
        super.init(start: .begin, ends: [.finish, .failed])
    }

}
