//
//  PlayApp.swift
//  PlayCover
//

import Cocoa
import Foundation
import IOKit.pwr_mgt

class PlayApp: BaseApp {
    private static let library = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")

    var searchText: String {
        info.displayName.lowercased().appending(" ").appending(info.bundleName).lowercased()
    }

    func launch() {
        do {
            if prohibitedToPlay {
                clearAllCache()
                throw PlayCoverError.appProhibited
            }
            if maliciousProhibited {
                clearAllCache()
                deleteApp()
                throw PlayCoverError.appMaliciousProhibited
            }
            AppsVM.shared.updatingApps = true
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
                    Shell.lldb(executable, withTerminalWindow: settings.openLLDBWithTerminal)
                } else {
                    runAppExec() // Splitting to reduce complexity
                }
            }

            AppsVM.shared.updatingApps = false
        } catch {
            AppsVM.shared.updatingApps = false
            Log.shared.error(error)
        }
    }

    func runAppExec() {
        let config = NSWorkspace.OpenConfiguration()

        if settings.metalHudEnabled {
            config.environment = ["MTL_HUD_ENABLED": "1"]
        } else {
            config.environment = ["MTL_HUD_ENABLED": "0"]
        }

        NSWorkspace.shared.openApplication(
            at: url,
            configuration: config,
            completionHandler: { runningApp, error in
                guard error == nil else { return }
                if self.settings.settings.disableTimeout {
                    // Yeet into a thread
                    Task {
                        debugPrint("Disabling timeout...")
                        let reason = "PlayCover: " + self.name + " disabled screen timeout" as CFString
                        var assertionID: IOPMAssertionID = 0
                        var success = IOPMAssertionCreateWithName(
                            kIOPMAssertionTypeNoDisplaySleep as CFString,
                            IOPMAssertionLevel(kIOPMAssertionLevelOn),
                            reason,
                            &assertionID)
                        if success == kIOReturnSuccess {
                            while true { // Run a loop until the app closes
                                try await Task.sleep(nanoseconds: 10000000000) // Sleep for 10 seconds
                                guard
                                    let isFinish = runningApp?.isTerminated,
                                    !isFinish else { break }
                            }
                            success = IOPMAssertionRelease(assertionID)
                            debugPrint("Enabling timeout...")
                        }
                    }
                }
            })
    }

    var name: String {
        if info.displayName.isEmpty {
            return info.bundleName
        } else {
            return info.displayName
        }
    }

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

    func isCodesigned() throws -> Bool {
        try shell.shello("/usr/bin/codesign", "-dv", executable.path).contains("adhoc")
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
            shell.signAppWith(executable, entitlements: tmpEnts)
            try FileManager.default.removeItem(at: tmpDir)
        } catch {
            print(error)
            Log.shared.error(error)
        }
    }

    func largerImage(image imageA: NSImage, compareTo imageB: NSImage?) -> NSImage {
        if imageA.size.height > imageB?.size.height ?? -1 {
            return imageA
        }
        return imageB!
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
        "com.garena.game.codm",
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
