//
//  PlayCoverApp.swift
//  PlayCover
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            if url.pathExtension == "ipa"{
                uif.ipaUrl = url
                Installer.install(ipaUrl : uif.ipaUrl! , returnCompletion: { (app) in
                    DispatchQueue.main.async {
                        AppsVM.shared.fetchApps()
                        NotifyService.shared.notify(NSLocalizedString("notification.appInstalled", comment: ""),
                                                    NSLocalizedString("notification.appInstalled.message", comment: ""))
                    }
                })
            }
        }
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        TempAllocator.clearTemp()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.register(
			defaults: ["NSApplicationCrashOnExceptions" : true]
		)
        LaunchServicesWrapper.setMyselfAsDefaultApplicationForFileExtension("ipa")
    }
    
}

@main
struct PlayCoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var showToast = false
    
    var body: some Scene {
        WindowGroup {
            MainView(showToast: $showToast)
                .padding()
                .environmentObject(UpdateService.shared)
                .environmentObject(InstallVM.shared)
                .environmentObject(AppsVM.shared)
                .environmentObject(AppIntegrity())
                .frame(minWidth: 720, minHeight: 650)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    UserDefaults.standard.register(defaults: ["ShowLinks" : true])
                    SoundDeviceService.shared.prepareSoundDevice()
                    UpdateService.shared.checkUpdate()
                    NotifyService.shared.allowNotify()
                }
                .padding(-15)
        }.windowStyle(HiddenTitleBarWindowStyle()).commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                EmptyView()
            }
        }.handlesExternalEvents(matching: Set(arrayLiteral: "{same path of URL?}")) // create new window if doesn't exist
            .commands {
                PlayCoverMenuView(showToast: $showToast)
                PlayCoverHelpMenuView()
                PlayCoverViewMenuView()
            }
    }
    
}
