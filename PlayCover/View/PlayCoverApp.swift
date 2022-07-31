//
//  PlayCoverApp.swift
//  PlayCover
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            if url.pathExtension == "ipa" {
                uif.ipaUrl = url
                Installer.install(ipaUrl: uif.ipaUrl!, returnCompletion: { (_) in
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
			defaults: ["NSApplicationCrashOnExceptions": true]
		)
    }

}

@main
struct PlayCoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var updaterViewModel = UpdaterViewModel()

    @State var showToast = false
    @State var xcodeCliInstalled = shell.isXcodeCliToolsInstalled

    var body: some Scene {
        WindowGroup {
            MainView(showToast: $showToast, xcodeCliInstalled: $xcodeCliInstalled)
                .padding()
                .environmentObject(InstallVM.shared)
                .environmentObject(AppsVM.shared)
                .environmentObject(AppIntegrity())
                .frame(minWidth: 660, minHeight: 650)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    UserDefaults.standard.register(defaults: ["ShowLinks": true])
                    SoundDeviceService.shared.prepareSoundDevice()
                    NotifyService.shared.allowNotify()
                }
                .padding(-15)
        }.windowStyle(HiddenTitleBarWindowStyle()).commands {
            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                EmptyView()
            }
        }
        .handlesExternalEvents(matching: ["{same path of URL?}"]) // create new window if doesn't exist
        .commands {
            PlayCoverMenuView(showToast: $showToast)
            PlayCoverHelpMenuView(updaterViewModel: updaterViewModel)
            PlayCoverViewMenuView()
        }

        Settings {
            PlayCoverSettingsView(updaterViewModel: updaterViewModel)
        }
    }
}
