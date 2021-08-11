//
//  PlayCoverApp.swift
//  PlayCover
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
            AppInstallView()
                .environmentObject(InstallAppViewModel.shared)
                .environmentObject(UserIntentFlow.shared)
                .environmentObject(ErrorViewModel.shared)
                .environmentObject(Logger.shared).accentColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
        }.windowStyle(HiddenTitleBarWindowStyle())
    }
    
    
}
