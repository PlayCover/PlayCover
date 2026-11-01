//
//  DownloadVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 01/10/2022.
//

import Foundation

nonisolated enum DownloadStepsNative: String, Sendable {
    case downloading = "playapp.download.downloading",
         integrity = "playapp.download.integrityCheck",
         finish = "playapp.progress.finished",
         failed = "playapp.progress.failed",
         canceled = "playapp.progress.canceled"
}

@Observable
final class DownloadVM: ProgressVM<DownloadStepsNative> {
    var storeAppData: SourceAppsData?

    static var shared: DownloadVM { AppEnvironment.shared.download }

    init() {
        super.init(start: .downloading, ends: [.finish, .failed, .canceled])
    }

}
