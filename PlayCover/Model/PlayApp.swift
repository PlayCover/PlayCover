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
    var sessionDisableKeychain: Bool = false

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

            // call unlockKeyCover() and WAIT for it to finish
            await unlockKeyCover()

            // If the app does not have PlayTools, do not install PlugIns
            if hasPlayTools() {
                try PlayTools.installPluginInIPA(url)
            }

            if try !PlayTools.isInstalled() {
                Log.shared.error("PlayTools are not installed! Please move PlayCover.app into Applications!")
            } else if try !Macho.isMachoValidArch(executable) {
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
                        sleep(1)
                    }
                    // Things that are ran after the app is closed
                    self.lockKeyCover()
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

    func unlockKeyCover() async {
        if KeyCover.shared.isKeyCoverEnabled() {
            // Check if the app have any keychains
            let keychain = KeyCover.shared.listKeychains()
                .first(where: { $0.appBundleID == self.info.bundleIdentifier })
            // Check the status of that keychain
            if let keychain = keychain, keychain.chainEncryptionStatus {
                // If the keychain is encrypted, unlock it
                try? await KeyCover.shared.unlockChain(keychain)

                if KeyCover.shared.keyCoverPlainTextKey == nil {
                    // Pop an alert telling the user that keychain was not unlocked
                    // and keychain is disabled for the session
                    Task { @MainActor in
                        let alert = NSAlert()
                        alert.messageText = NSLocalizedString("keycover.alert.title", comment: "")
                        alert.informativeText = NSLocalizedString("keycover.alert.content", comment: "")
                        alert.alertStyle = .warning
                        alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
                        alert.runModal()
                    }
                    settings.settings.playChain = false
                    sessionDisableKeychain = true
                }

            }
        }
    }

    func lockKeyCover() {
        if KeyCover.shared.isKeyCoverEnabled() {
            if sessionDisableKeychain {
                settings.settings.playChain = true
                sessionDisableKeychain = false
                return
            }
            // Check if the app have any keychains
            let keychain = KeyCover.shared.listKeychains()
                .first(where: { $0.appBundleID == self.info.bundleIdentifier })
            // Check the status of that keychain
            if let keychain = keychain, !keychain.chainEncryptionStatus {
                // If the keychain is encrypted, lock it
                try? KeyCover.shared.lockChain(keychain)
            }
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

    func introspection(set: Bool? = nil) -> Bool {
        if info.lsEnvironment["DYLD_LIBRARY_PATH"] == nil {
            info.lsEnvironment["DYLD_LIBRARY_PATH"] = ""
        }

        if let set = set {
            if set {
                info.lsEnvironment["DYLD_LIBRARY_PATH"]? += "/usr/lib/system/introspection:"
            } else {
                info.lsEnvironment["DYLD_LIBRARY_PATH"] = info.lsEnvironment["DYLD_LIBRARY_PATH"]?
                    .replacingOccurrences(of: "/usr/lib/system/introspection:", with: "")
            }

            do {
                try Shell.signApp(executable)
            } catch {
                Log.shared.error(error)
            }
        }

        guard let introspection = info.lsEnvironment["DYLD_LIBRARY_PATH"] else {
            return false
        }

        return introspection.contains("/usr/lib/system/introspection")
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
        FileManager.default.delete(at: playChainURL.appendingPathExtension("keyCover"))
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
        "com.dts.freefiremax",
        "vn.vng.codmvn",
        "com.ngame.allstar.eu"
    ]

    static let MALICIOUS_APPS = [
        "com.zhiliaoapp.musically"
    ]
}
