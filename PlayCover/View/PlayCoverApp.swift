//
//  PlayCoverApp.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import SwiftUI

@main
struct PlayCoverApp: App {
    var body: some Scene {
        WindowGroup {
            AppLibraryView()
                .environmentObject(InstalViewModel.shared)
                .environmentObject(Logger.shared)
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
}
