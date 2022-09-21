//
//  PlayApp.swift
//  PlayCover
//

import Cocoa
import Foundation
import IOKit.pwr_mgt

class PlayApp: BaseApp {
    var searchText: String {
        info.displayName.lowercased().appending(" ").appending(info.bundleName).lowercased()
    }

    func launch() {
        do {
            if prohibitedToPlay {
                container?.clear()
                throw PlayCoverError.appProhibited
            }

            AppsVM.shared.updatingApps = true
            AppsVM.shared.fetchApps()
            settings.sync()
            if try !Entitlements.areEntitlementsValid(app: self) {
                sign()
            }
            try PlayTools.installPluginInIPA(url)
            if try !PlayTools.isInstalled() {
                Log.shared.error("PlayTools are not installed! Please move PlayCover.app into Applications!")
            } else if try !PlayTools.isValidArch(executable.path) {
                Log.shared.error("The app threw an error during conversion.")
            } else if try !isCodesigned() {
                Log.shared.error("The app is not codesigned! Please open Xcode and accept license agreement.")
            } else {
                runAppExec() // Splitting to reduce complexity
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
                    DispatchQueue.global().async {
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
                                Thread.sleep(forTimeInterval: 10) // Wait 10s
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

    var icon: NSImage? {
        var highestRes: NSImage?
        let appDirectoryURL = PlayTools.playCoverContainer
            .appendingPathComponent(info.executableName)
            .appendingPathExtension("app")
        let appDirectoryPath = "\(appDirectoryURL.relativePath)/"

        if let assetsExtractor = try? AssetsExtractor(appUrl: appDirectoryURL) {
            for icon in assetsExtractor.extractIcons() {
                highestRes = largerImage(image: icon, compareTo: highestRes)
            }
        }

        guard let items = try? FileManager.default.contentsOfDirectory(atPath: appDirectoryPath) else {
            return highestRes
        }
        for item in items where item.hasPrefix(info.primaryIconName) {
            do {
                if let image = NSImage(data: try Data(contentsOf: URL(fileURLWithPath: "\(appDirectoryPath)\(item)"))) {
                    highestRes = largerImage(image: image, compareTo: highestRes)
                }
            } catch {
                Log.shared.error(error)
            }
        }
        return highestRes
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

    func isCodesigned() throws -> Bool {
        try shell.shello("/usr/bin/codesign", "-dv", executable.path).contains("adhoc")
    }

    func showInFinder() {
        URL(fileURLWithPath: url.path).showInFinderAndSelectLastComponent()
    }

    func openAppCache() {
        container?.containerUrl.showInFinderAndSelectLastComponent()
    }

    func deleteApp() {
        do {
            try FileManager.default.delete(at: URL(fileURLWithPath: url.path))
            AppsVM.shared.fetchApps()
        } catch {
            Log.shared.error(error)
        }
    }

    func sign() {
        do {
            let tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                  in: .userDomainMask,
                                                  appropriateFor: URL(fileURLWithPath: "/Users"),
                                                  create: true)
            let tmpEnts = tmpDir
                .appendingPathComponent(ProcessInfo().globallyUniqueString)
                .appendingPathExtension("plist")
            let conf = try Entitlements.composeEntitlements(self)
            try conf.store(tmpEnts)
            shell.signAppWith(executable, entitlements: tmpEnts)
            try FileManager.default.removeItem(at: tmpEnts)
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
}
