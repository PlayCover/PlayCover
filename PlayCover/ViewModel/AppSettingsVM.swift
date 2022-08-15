//
//  AppSettingsVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 15/08/2022.
//

import Foundation

class AppSettingsVM: ObservableObject {
    @Published var appSettings: AppSettings?
    
    init(_ appSettings: AppSettings? = nil) {
        if let appSettings = appSettings {
            self.appSettings = appSettings
        } else {
            self.appSettings = nil
        }
    }
    
    func update(_ appSettings: AppSettings) {
        self.appSettings = appSettings
    }
}
