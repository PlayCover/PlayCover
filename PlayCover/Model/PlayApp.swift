//
//  PlayApp.swift
//  PlayCover
//

import Foundation
import Cocoa
import IOKit.pwr_mgt

class PlayApp: BaseApp {
    var searchText: String {
        return info.displayName.lowercased().appending(" ").appending(info.bundleName).lowercased()
    }

    func launch() {
        do {
            if prohibitedToPlay {
                container?.clear()
                throw PlayCoverError.appProhibited
            }

            AppsVM.shared.updatingApps = true
            AppsVM.shared.fetchApps()
            self.settings.sync()
            if try !Entitlements.areEntitlementsValid(app: self) {
                sign()
            }
            if try !PlayTools.isInstalled() {
                Log.shared.msg("PlayTools are not installed! Please move PlayCover.app into Applications!")
            } else if try !PlayTools.isValidArch(executable.path) {
                Log.shared.msg("The app threw an error during conversion.")
            } else if try !isCodesigned() {
                Log.shared.msg("The app is not codesigned! Please open Xcode and accept license agreement.")
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
        NSWorkspace.shared.openApplication(at: url,
                                           configuration: NSWorkspace.OpenConfiguration(),
                                           completionHandler: {runningApp, error in
            guard error == nil else {return}
            if self.settings.disableTimeout {
                // Yeet into a thread
                DispatchQueue.global().async {
                    debugPrint("Disabling timeout...")
                    let reason = "PlayCover: " + self.name + " disabled screen timeout" as CFString
                    var assertionID: IOPMAssertionID = 0
                    var success = IOPMAssertionCreateWithName( kIOPMAssertionTypeNoDisplaySleep as CFString,
                                                               IOPMAssertionLevel(kIOPMAssertionLevelOn),
                                                               reason,
                                                               &assertionID )
                    if success == kIOReturnSuccess {
                        while true { // Run a loop until the app closes
                            Thread.sleep(forTimeInterval: 10) // Wait 10s
                            guard let isFinish = runningApp?.isTerminated,
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
        if let rep = NSWorkspace.shared.icon(forFile: url.path)
            .bestRepresentation(for: NSRect(x: 0, y: 0, width: 128, height: 128), context: nil, hints: nil) {
            let image = NSImage(size: rep.size)
            image.addRepresentation(rep)
            return image
        }
        return nil
    }

    var name: String {
        if info.displayName.isEmpty {
            return info.bundleName
        } else {
            return info.displayName
        }
    }

    lazy var settings: AppSettings = {
        AppSettings(info, container: container)
    }()

    var container: AppContainer?

    func isCodesigned() throws -> Bool {
        return try shell.shello(
            "/usr/bin/codesign",
            "-dv",
            executable.path
        ).contains("adhoc")
    }

    func showInFinder() {
        URL(fileURLWithPath: url.path).showInFinderAndSelectLastComponent()
    }

    func openAppCache() {
        container?.containerUrl.showInFinderAndSelectLastComponent()
    }

    func deleteApp() {
        do {
            try fileMgr.delete(at: URL(fileURLWithPath: url.path))
            AppsVM.shared.fetchApps()
        } catch {
            Log.shared.error(error)
        }
    }

    func sign() {
        do {
            let tmpEnts = try TempAllocator.allocateTempDirectory().appendingPathComponent("entitlements.plist")
            let conf = try Entitlements.composeEntitlements(self)
            try conf.store(tmpEnts)
            shell.signAppWith(executable, entitlements: tmpEnts)
            TempAllocator.clearTemp()
        } catch {
            print(error)
            Log.shared.error(error)
        }
    }

    var prohibitedToPlay: Bool {
        return PlayApp.PROHIBITED_APPS.contains(info.bundleIdentifier)
    }

    static let PROHIBITED_APPS = ["com.activision.callofduty.shooter",
                                  "com.garena.game.codm",
                                  "com.tencent.tmgp.cod",
                                  "com.tencent.ig",
                                  "com.pubg.newstate",
                                  "com.tencent.tmgp.pubgmhd",
                                  "com.dts.freefireth",
                                  "com.dts.freefiremax"]
}
