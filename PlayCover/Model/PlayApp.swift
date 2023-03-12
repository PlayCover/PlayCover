//
//  PlayApp.swift
//  PlayCover
//

import Cocoa
import Foundation
import IOKit.pwr_mgt

class PlayApp: BaseApp {
    private static let library = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
    var displaySleepAssertionID: IOPMAssertionID?
    public var isStarting = false

    var searchText: String {
        info.displayName.lowercased().appending(" ").appending(info.bundleName).lowercased()
    }

    func launch() async {
        do {
            isStarting = true
            if prohibitedToPlay {
                clearAllCache()
                throw PlayCoverError.appProhibited
            } else if maliciousProhibited {
                clearAllCache()
                deleteApp()
                throw PlayCoverError.appMaliciousProhibited
            }

            AppsVM.shared.fetchApps()
            settings.sync()

            if try !Entitlements.areEntitlementsValid(app: self) {
                sign()
            }

            // If the app does not have PlayTools, do not install PlugIns
            if hasPlayTools() {
                try PlayTools.installPluginInIPA(url)
            }

            if try !PlayTools.isInstalled() {
                Log.shared.error("PlayTools are not installed! Please move PlayCover.app into Applications!")
            } else if try !PlayTools.isMachoValidArch(executable) {
                Log.shared.error("The app threw an error during conversion.")
            } else if try !isCodesigned() {
                Log.shared.error("The app is not codesigned! Please open Xcode and accept license agreement.")
            } else {
                if settings.openWithLLDB {
                    try Shell.lldb(executable, withTerminalWindow: settings.openLLDBWithTerminal)
                } else {
                    runAppExec() // Splitting to reduce complexity
                }
            }
            isStarting = false
        } catch {
            Log.shared.error(error)
        }
    }

    func runAppExec() {
        let config = NSWorkspace.OpenConfiguration()

        if settings.settings.metalHUD {
            config.environment = ["MTL_HUD_ENABLED": "1"]
        } else {
            config.environment = ["MTL_HUD_ENABLED": "0"]
        }

        if settings.settings.injectIntrospection {
            config.environment["DYLD_LIBRARY_PATH"] = "/usr/lib/system/introspection"
        }

        NSWorkspace.shared.openApplication(
            at: url,
            configuration: config,
            completionHandler: { runningApp, error in
                guard error == nil else { return }
                // Run a thread loop in the background to handle background tasks
                Task(priority: .background) {
                    if let runningApp = runningApp {
                        while !(runningApp.isTerminated) {
                            // Check if the app is in the foreground
                            if runningApp.isActive {
                                // If the app is in the foreground, disable the display sleep
                                self.disableTimeOut()
                            } else {
                                // If the app is not in the foreground, enable the display sleep
                                self.enableTimeOut()
                            }
                            sleep(1)
                        }
                    }
                }
            })
    }

    func disableTimeOut() {
        if displaySleepAssertionID != nil {
            return
        }
        // Disable display sleep
        let reason = "PlayCover: \(info.bundleIdentifier) is disabling sleep" as CFString
        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID)
        if result == kIOReturnSuccess {
            displaySleepAssertionID = assertionID
        }
    }

    func enableTimeOut() {
        // Enable display sleep
        if let assertionID = displaySleepAssertionID {
            IOPMAssertionRelease(assertionID)
            displaySleepAssertionID = nil
        }
    }

    var name: String {
        if info.displayName.isEmpty {
            return info.bundleName
        } else {
            return info.displayName
        }
    }

    static let aliasDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Applications")
            .appendingPathComponent("PlayCover")

    static let playChainDirectory = PlayTools.playCoverContainer.appendingPathComponent("PlayChain")

    lazy var aliasURL = PlayApp.aliasDirectory.appendingPathComponent(name)

    lazy var playChainURL = PlayApp.playChainDirectory.appendingPathComponent(info.bundleIdentifier)

    lazy var settings = AppSettings(info, container: container)

    lazy var keymapping = Keymapping(info, container: container)

    var container: AppContainer?

    func hasPlayTools() -> Bool {
        do {
            return try PlayTools.installedInExec(atURL: url.appendingEscapedPathComponent(info.executableName))
        } catch {
            Log.shared.error(error)
            return true
        }
    }

    func hasAlias() -> Bool {
        return FileManager.default.fileExists(atPath: aliasURL.path)
    }

    func isCodesigned() throws -> Bool {
        try Shell.run("/usr/bin/codesign", "-dv", executable.path).contains("adhoc")
    }

    func showInFinder() {
        URL(fileURLWithPath: url.path).showInFinderAndSelectLastComponent()
    }

    func openAppCache() {
        container?.containerUrl.showInFinderAndSelectLastComponent()
    }

    func clearAllCache() {
        Uninstaller.clearExternalCache(info.bundleIdentifier)
    }

    func clearPlayChain() {
        FileManager.default.delete(at: playChainURL)
    }

    func createAlias() {
        do {
            try FileManager.default.createDirectory(atPath: PlayApp.aliasDirectory.path,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
            let data = try url.bookmarkData(options: .suitableForBookmarkFile,
                                                includingResourceValuesForKeys: nil, relativeTo: nil)
            try URL.writeBookmarkData(data, to: aliasURL)
        } catch {
            Log.shared.log(error.localizedDescription)
        }
    }

    func removeAlias() {
        FileManager.default.delete(at: aliasURL)
    }

    func deleteApp() {
        FileManager.default.delete(at: URL(fileURLWithPath: url.path))
        AppsVM.shared.fetchApps()
    }

    func sign() {
        do {
            let tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: URL(fileURLWithPath: "/Users"),
                                                  create: true)
            let tmpEnts = tmpDir
                .appendingEscapedPathComponent(ProcessInfo().globallyUniqueString)
                .appendingPathExtension("plist")
            let conf = try Entitlements.composeEntitlements(self)
            try conf.store(tmpEnts)
            try Shell.signAppWith(executable, entitlements: tmpEnts)
            try FileManager.default.removeItem(at: tmpDir)
        } catch {
            print(error)
            Log.shared.error(error)
        }
    }

    var prohibitedToPlay: Bool {
        PlayApp.PROHIBITED_APPS.contains(info.bundleIdentifier)
    }

    var maliciousProhibited: Bool {
        PlayApp.MALICIOUS_APPS.contains(info.bundleIdentifier)
    }

    static let PROHIBITED_APPS = [
        "com.activision.callofduty.shooter",
        "com.ea.ios.apexlegendsmobilefps",
        "com.tencent.tmgp.cod",
        "com.tencent.ig",
        "com.pubg.newstate",
        "com.tencent.tmgp.pubgmhd",
        "com.dts.freefireth",
        "com.dts.freefiremax"
    ]

    static let MALICIOUS_APPS = [
        "com.zhiliaoapp.musically"
    ]
}
