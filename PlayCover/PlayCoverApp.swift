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
            if !checkIfXcodeInstalled(){
                ToolsInstallView()
            } else {
                AppLibraryView().environmentObject(UserData())
            }
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
}
