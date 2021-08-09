//
//  PlayCoverApp.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationWillTerminate(_ aNotification: Notification) {
        fm.clearCache()
    }
}

@main
struct PlayCoverApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            AppLibraryView()
                .environmentObject(InstalViewModel.shared)
                .environmentObject(Logger.shared).accentColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
    
    
}
