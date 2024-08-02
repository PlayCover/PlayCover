//
//  PlayAppVM.swift
//  PlayCover
//
//  Created by Adam Chen JingFan on 4/7/24.
//

import SwiftUI

class PlayAppVM: ObservableObject {
    @Published var app: PlayApp
    @Published var showSettings = false
    @Published var showClearPreferencesAlert = false
    @Published var showClearPlayChainAlert = false
    @Published var showStartingProgress = false
    @Published var showImportSuccess = false
    @Published var showImportFail = false

    init(app: PlayApp) {
        self.app = app
    }
}
