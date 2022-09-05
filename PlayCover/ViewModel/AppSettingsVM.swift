//
//  AppSettingsVM.swift
//  PlayCover
//
//  Created by 이승윤 on 2022/08/15.
//

import Foundation

class AppSettingsVM: ObservableObject {

    let app: PlayApp
    @Published var settings: AppSettings

    init(app: PlayApp) {
        self.app = app
        settings = app.settings
    }
}
