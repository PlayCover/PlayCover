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
                Installer.install(ipaUrl: uif.ipaUrl!, returnCompletion: { _ in
                    DispatchQueue.main.async {
                        AppsVM.shared.fetchApps()
                        NotifyService.shared.notify(
                            NSLocalizedString("notification.appInstalled", comment: ""),
                            NSLocalizedString("notification.appInstalled.message", comment: ""))
                    }
                })
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
		UserDefaults.standard.register(
			defaults: ["NSApplicationCrashOnExceptions": true]
		)
    }

}

func dirCheck() -> Bool {
    let langCode  = Locale.current.languageCode
    let rtlLangs = [ "ar", "arc", "dv", "fa", "ha", "he", "khw", "ks", "ku", "ps", "ur", "yi" ]
    return rtlLangs.contains(langCode!)
}
public var direction = (dirCheck() == true ? LayoutDirection.rightToLeft : LayoutDirection.leftToRight)

@main
struct PlayCoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var updaterViewModel = UpdaterViewModel()

    @State var xcodeCliInstalled = shell.isXcodeCliToolsInstalled
    @State var isSigningSetupShown = false

    var body: some Scene {
        WindowGroup {
            MainView(xcodeCliInstalled: $xcodeCliInstalled,
                     isSigningSetupShown: $isSigningSetupShown)
                .environmentObject(InstallVM.shared)
                .environmentObject(AppsVM.shared)
                .environmentObject(StoreVM.shared)
                .environmentObject(AppIntegrity())
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    SoundDeviceService.shared.prepareSoundDevice()
                    NotifyService.shared.allowNotify()
                }
                .environment(\.layoutDirection, direction)
        }
        .handlesExternalEvents(matching: ["{same path of URL?}"]) // create new window if doesn't exist
        .commands {
            PlayCoverMenuView(isSigningSetupShown: $isSigningSetupShown)
            PlayCoverHelpMenuView(updaterViewModel: updaterViewModel)
            PlayCoverViewMenuView()
            SidebarCommands()
        }

        Settings {
            PlayCoverSettingsView(updaterViewModel: updaterViewModel)
        }
    }
}
