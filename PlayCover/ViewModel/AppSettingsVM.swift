//
//  AppSettingsVM.swift
//  PlayCover
//
//  Created by 이승윤 on 2022/08/15.
//

import Foundation
import Observation

@Observable
final class AppSettingsVM {
    let app: PlayApp
    var settings: AppSettings

    init(app: PlayApp) {
        self.app = app
        settings = app.settings
    }
}
