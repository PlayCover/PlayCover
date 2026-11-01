//
//  PlayAppVM.swift
//  PlayCover
//
//  Created by Adam Chen JingFan on 4/7/24.
//

import SwiftUI

@Observable
final class PlayAppVM {
    var app: PlayApp
    var showSettings = false
    var showClearPreferencesAlert = false
    var showClearPlayChainAlert = false
    var showStartingProgress = false
    var showImportSuccess = false
    var showImportFail = false
    var showKeymapSheet = false

    init(app: PlayApp) {
        self.app = app
    }
}
