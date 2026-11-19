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
            let keyCoverPassword = KeyCoverPassword.shared.generateVerySecurePassword()
            KeyCoverPassword.shared.setKeyCoverPassword(keyCoverPassword)
            KeyCoverPreferences.shared.keyCoverEnabled = .selfGeneratedPassword
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
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("alert.power.title", comment: "")
            alert.informativeText = NSLocalizedString("alert.power.subtitle", comment: "")
            alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
            alert.showsSuppressionButton = true
            alert.alertStyle = .critical

            if alert.runModal() == .alertFirstButtonReturn {
                showLowPowerModeAlert = alert.suppressionButton?.state == .off
            }
        }
    }
}

@main
enum PlayCoverLauncher {
    @MainActor
    static func main() {
        if let ipaPath = parseInstallIPAPath(from: CommandLine.arguments) {
            runHeadlessInstall(ipaPath: ipaPath)
            return
        }
        PlayCoverApp.main()
    }

    private static func parseInstallIPAPath(from arguments: [String]) -> String? {
        if let equalsArg = arguments.first(where: { $0.hasPrefix("--install-ipa=") }) {
            return String(equalsArg.dropFirst("--install-ipa=".count))
        }
        guard let flagIndex = arguments.firstIndex(of: "--install-ipa") else {
            return nil
        }
        let pathIndex = arguments.index(after: flagIndex)
        guard pathIndex < arguments.endIndex else {
            return ""
        }
        return arguments[pathIndex]
    }

    @MainActor
    private static func runHeadlessInstall(ipaPath: String) {
        let expandedPath = (ipaPath as NSString).expandingTildeInPath
        let ipaURL = URL(fileURLWithPath: expandedPath).standardizedFileURL
        guard !ipaPath.isEmpty, FileManager.default.fileExists(atPath: ipaURL.path) else {
            writeStderr("ERROR: IPA file not found: \(ipaPath)\n")
            Foundation.exit(1)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)

        Task.detached(priority: .userInitiated) {
            do {
                try PlayTools.installOnSystemSync()
                let installedApp = try await Installer.installCLI(ipaUrl: ipaURL)
                let bundleId = installedApp.info.bundleIdentifier
                let appPath = installedApp.url.path
                print("INSTALLED|\(bundleId)|\(appPath)")
                fflush(stdout)
                Foundation.exit(0)
            } catch {
                writeStderr("ERROR: \(error.localizedDescription)\n")
                fflush(stderr)
                Foundation.exit(1)
            }
        }

        while true {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }
    }

    private static func writeStderr(_ message: String) {
        if let data = message.data(using: .utf8) {
            FileHandle.standardError.write(data)
        }
    }
}

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
