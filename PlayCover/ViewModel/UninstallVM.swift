//
//  UninstallVM.swift
//  PlayCover
//

import Foundation

enum UninstallStepsNative: String {
    case begin = "playapp.uninstall.begin",
         clearCache = "playapp.clearCache.begin",
         appCacheCleared = "alert.appCacheCleared",
         finish = "playapp.uninstall.finished"
}

class UninstallVM: ProgressVM<UninstallStepsNative> {
    static let shared = UninstallVM()

    init() {
        super.init(start: .begin, ends: [.appCacheCleared, .finish])
    }

}
