//
//  ExportAppVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 12/19/24.
//

import Foundation

enum ExportAppStepsNative: String {
    case copy = "playapp.exportApp.copy",
         zip = "playapp.exportApp.zip",
         deleteTmp = "playapp.exportApp.deleteTmp",
         finish = "playapp.exportApp.finished",
         failed = "playapp.exportApp.failed"
}

class ExportAppVM: ProgressVM<ExportAppStepsNative> {

    static let shared = ExportAppVM()

    init() {
        super.init(start: .copy, ends: [.finish, .failed])
    }

}
