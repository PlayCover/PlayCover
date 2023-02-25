//
//  PlayCoverApp.swift
//  PlayCover
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            URLHandler.shared.processURL(url: url)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(
            defaults: ["NSApplicationCrashOnExceptions": true]
        )
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(powerStateChanged),
                                               name: Notification.Name.NSProcessInfoPowerStateDidChange,
                                               object: nil)
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            powerModal()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    @objc func powerStateChanged(_ notification: Notification) {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            Task { @MainActor in
                self.powerModal()
            }
        }
    }

    func powerModal() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("alert.power.title", comment: "")
        alert.informativeText = NSLocalizedString("alert.power.subtitle", comment: "")
        alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
        alert.alertStyle = .critical
        alert.runModal()
    }
}

@main
struct PlayCoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var updaterViewModel = UpdaterViewModel()
    var storeVM = StoreVM.shared

    @State var isSigningSetupShown = false

    var body: some Scene {
        WindowGroup {
            MainView(isSigningSetupShown: $isSigningSetupShown)
                .environmentObject(InstallVM.shared)
                .environmentObject(DownloadVM.shared)
                .environmentObject(AppsVM.shared)
                .environmentObject(storeVM)
                .environmentObject(AppIntegrity())
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                    SoundDeviceService.shared.prepareSoundDevice()
                    NotifyService.shared.allowNotify()
                }
        }
        .handlesExternalEvents(matching: ["{same path of URL?}"]) // create new window if doesn't exist
        .commands {
            SidebarCommands()
            PlayCoverMenuView(isSigningSetupShown: $isSigningSetupShown)
            PlayCoverHelpMenuView(updaterViewModel: updaterViewModel)
            PlayCoverViewMenuView()
        }

        Settings {
            PlayCoverSettingsView(updaterViewModel: updaterViewModel)
                .environmentObject(storeVM)
        }
    }
}
