//
//  PlayCoverApp.swift
//  PlayCover
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    @AppStorage("ShowLowPowerModeAlert") var showLowPowerModeAlert = true

    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            URLHandler.shared.processURL(url: url)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UpdateScheme.checkForUpdate()

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
        URLCache.iconCache.removeAllCachedResponses()
        // Code that run once on first launch
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if !launchedBefore {
            UserDefaults.standard.set(true, forKey: "launchedBefore")

            // Initialize KeyCover with an automatically generated key
            let keyCover = KeyCoverService.shared
            Task {
                await keyCover.setPassword(keyCover.generateVerySecurePassword(), status: .selfGeneratedPassword)
            }
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
        if showLowPowerModeAlert {
            let response = AlertPresenter.shared.presentModal(AlertRequest(
                title: NSLocalizedString("alert.power.title", comment: ""),
                message: NSLocalizedString("alert.power.subtitle", comment: ""),
                style: .critical,
                suppressionTooltip: NSLocalizedString("alert.supression", comment: "")
            ))
            if response.isFirstButton {
                showLowPowerModeAlert = !response.isSuppressed
            }
        }
    }
}

@main
enum PlayCoverMain {
    static func main() {
        if isHostingTests {
            // Tests are injected into this process; skip the UI and its launch side effects
            // (PlayTools install, library scan, migrations) so they never touch real user data.
            NSApplication.shared.setActivationPolicy(.prohibited)
            NSApplication.shared.run()
        } else {
            PlayCoverApp.main()
        }
    }

    private static var isHostingTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil || environment["XCTestSessionIdentifier"] != nil
    }
}

struct PlayCoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var updaterViewModel = UpdaterViewModel()
    private let environment = AppEnvironment.shared

    @State var isSigningSetupShown = false

    init() {
        environment.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            MainView(isSigningSetupShown: $isSigningSetupShown)
                .appEnvironment(environment)
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
                .appEnvironment(environment)
        }
    }
}
