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
                AppLibraryView().environmentObject(UserData())
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
}
