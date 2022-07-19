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
                        NotifyService.shared.notify("App is installed!", "Please, check it out in 'My Apps'")
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
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .padding()
                .environmentObject(UpdateService.shared)
                .environmentObject(InstallVM.shared)
                .environmentObject(AppsVM.shared)
                .environmentObject(AppIntegrity())
                .frame(minWidth: 720, minHeight: 650)
                .onAppear {
                    UserDefaults.standard.register(defaults: ["ShowLinks" : true])
                    SoundDeviceService.shared.prepareSoundDevice()
                    UpdateService.shared.checkUpdate()
                    NotifyService.shared.allowNotify()
                }
                .padding(-15)
        }.windowStyle(.titleBar).commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                EmptyView()
            }
        }.handlesExternalEvents(matching: Set(arrayLiteral: "{same path of URL?}")) // create new window if doesn't exist
            .commands {
                CommandGroup(after: .help) {
                    Divider()
                    Button("Website") {
                        NSWorkspace.shared.open(URL(string: "https://playcover.io")!)

                    }
                    Button("GitHub") {
                        NSWorkspace.shared.open(URL(string:"https://github.com/PlayCover/PlayCover/")!)
                    }
                    Button("Documentation") {
                        NSWorkspace.shared.open(URL(string:"https://github.com/PlayCover/PlayCover/wiki")!)
                    }
                    Button("Discord") {
                        NSWorkspace.shared.open(URL(string: "https://discord.gg/PlayCover")!)
                    }
                }
                CommandGroup(after: .systemServices) {
                    Button("Copy log") {
                        Log.shared.logdata.copyToClipBoard()
                    }
                }
            }
            .windowToolbarStyle(.unified)
    }
    
}
