//
//  UninstallVM.swift
//  PlayCover
//

import Foundation

enum UninstallStepsNative: String {
    case begin = "playapp.uninstall.begin",
         finish = "playapp.uninstall.finished"
}

class UninstallVM: ProgressVM<UninstallStepsNative> {
    static let shared = UninstallVM()

    init() {
        super.init(start: .begin, ends: [.finish])
    }

}
