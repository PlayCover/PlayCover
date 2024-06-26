//
//  Uninstaller.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 9/26/22.
//

import SwiftUI

struct CheckBoxHelper {
    var view: NSView
    var button: NSButton
    var buttonvar: String
}

class Uninstaller {
    private static let libraryUrl = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
    private static let pruneURLs: [URL] = [
        PlayTools.playCoverContainer.appendingPathComponent("App Settings"),
        PlayTools.playCoverContainer.appendingPathComponent("Entitlements"),
        PlayTools.playCoverContainer.appendingPathComponent("Keymapping"),
        PlayTools.playCoverContainer.appendingPathComponent("PlayChain")
    ]
    private static let cacheURLs: [URL] = [
        Uninstaller.libraryUrl.appendingPathComponent("Containers"),
        Uninstaller.libraryUrl.appendingPathComponent("Application Scripts"),
        Uninstaller.libraryUrl.appendingPathComponent("Caches"),
        Uninstaller.libraryUrl.appendingPathComponent("HTTPStorages"),
        Uninstaller.libraryUrl.appendingPathComponent("Saved Application State")
    ]

    private static func createButtonView(_ yaxis: CGFloat, _ text: String, _ varname: String) -> CheckBoxHelper {
        let button = NSButton(checkboxWithTitle: text, target: self, action: nil)

        if UninstallPreferences.shared.value(forKey: varname) as? Bool ?? true {
            button.animator().setNextState()
        }

        let view = NSView(frame: NSRect(x: 0, y: yaxis,
                                        width: button.fittingSize.width,
                                        height: button.fittingSize.height))

        view.addSubview(button)

        return CheckBoxHelper(view: view, button: button, buttonvar: varname)
    }

    @MainActor
    static func uninstallPopup(_ app: PlayApp) async {
        if UninstallPreferences.shared.showUninstallPopup {
            let boxmakers: [(String, String)] = [
                ("removePlayChain", NSLocalizedString("preferences.toggle.removePlayChain", comment: "")),
                ("removeAppEntitlements", NSLocalizedString("preferences.toggle.removeEntitlements", comment: "")),
                ("removeAppSettings", NSLocalizedString("preferences.toggle.removeSetting", comment: "")),
                ("removeAppKeymap", NSLocalizedString("preferences.toggle.removeKeymap", comment: "")),
                ("clearAppData", NSLocalizedString("preferences.toggle.clearAppData", comment: ""))
            ]

            var checkboxes: [CheckBoxHelper] = []

            var viewY = 0.0

            for (buttonvar, buttontitle) in boxmakers {
                checkboxes.append(createButtonView(viewY, buttontitle, buttonvar))
                viewY += checkboxes[checkboxes.count - 1].view.frame.height
            }

            let viewWidth = checkboxes.max(by: { $0.view.frame.width < $1.view.frame.width })?.view.frame.width

            let settingsView = NSStackView(frame: NSRect(x: 0, y: 0, width: viewWidth ?? 0, height: viewY))

            for checkboxhelper in checkboxes {
                settingsView.addSubview(checkboxhelper.view)
            }

            let alert = NSAlert()
            alert.messageText = NSLocalizedString("playapp.delete", comment: "")
            alert.informativeText = String(format: NSLocalizedString("playapp.deleteMessage",
                                                                     comment: ""),
                                           arguments: [app.name])

            alert.alertStyle = .warning
            alert.accessoryView = settingsView

            let delete = alert.addButton(withTitle: NSLocalizedString("playapp.deleteConfirm", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))

            alert.showsSuppressionButton = true
            alert.suppressionButton?.toolTip = NSLocalizedString("alert.supression", comment: "")

            delete.hasDestructiveAction = true

            NSApplication.shared.requestUserAttention(.criticalRequest)
            guard let window = NSApplication.shared.windows.first,
                  await alert.beginSheetModal(for: window) == .alertFirstButtonReturn else { return }
            for checkboxhelper in checkboxes {
                UninstallPreferences.shared.setValue(checkboxhelper.button.state == .on,
                                                     forKey: checkboxhelper.buttonvar)
            }

            if alert.suppressionButton?.state == .on {
                UninstallPreferences.shared.showUninstallPopup = false
            }

            await uninstall(app)
        } else {
            await uninstall(app)
        }
    }

    static func uninstall(_ app: PlayApp) async {
        var uninstallNum = 0

        if UninstallPreferences.shared.clearAppData {
            await app.clearAllCache()
            uninstallNum += 1
        }

        if UninstallPreferences.shared.removeAppKeymap {
            FileManager.default.delete(at: app.keymapping.keymapURL)
            uninstallNum += 1
        }

        if UninstallPreferences.shared.removeAppSettings {
            FileManager.default.delete(at: app.settings.settingsUrl)
            uninstallNum += 1
        }

        if UninstallPreferences.shared.removeAppEntitlements {
            FileManager.default.delete(at: app.entitlements)
            uninstallNum += 1
        }

        if UninstallPreferences.shared.removePlayChain {
            let url = PlayTools.playCoverContainer
                .appendingPathComponent("PlayChain")
                .appendingPathComponent(app.info.bundleIdentifier)
            FileManager.default.delete(at: url)

            // KeyCover encrypted chain
            let keyCoverURL = url.appendingPathExtension("keyCover")
            FileManager.default.delete(at: keyCoverURL)
            uninstallNum += 1
        }

        app.removeAlias()
        app.deleteApp()

        if uninstallNum >= 5 {
            do {
                let apps = (try PlayApp.bundleIDCache).filter({ $0 != app.info.bundleIdentifier })
                    .joined(separator: "\n") + "\n"
                try apps.write(to: PlayApp.bundleIDCacheURL, atomically: false, encoding: .utf8)
            } catch {
                Log.shared.error(error)
            }
        }
    }

    @MainActor
    static func clearCachePopup(_ app: PlayApp) async {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("alert.app.delete", comment: "")
        alert.alertStyle = .warning

        let proceed = alert.addButton(withTitle: NSLocalizedString("button.Proceed", comment: ""))
        proceed.hasDestructiveAction = true
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))

        NSApplication.shared.requestUserAttention(.criticalRequest)
        guard let window = NSApplication.shared.windows.first,
              await alert.beginSheetModal(for: window) == .alertFirstButtonReturn else { return }

        await clearCache(of: app)
    }

    static func clearCache(of app: PlayApp) async {
        await app.clearAllCache()
    }

    static func clearExternalCache(_ bundleId: String) {
        do {
            for cache in cacheURLs {
                cache.enumerateContents(options: [.skipsSubdirectoryDescendants]) { file, _ in
                    if file.path.contains(bundleId) {
                        try FileManager.default.trashItem(at: file, resultingItemURL: nil)
                    }
                }
            }
        }
    }

    static func pruneFiles() {
        do {
            let bundleIds = AppsVM.shared.apps.map { $0.info.bundleIdentifier }
            let danglingItems = try PlayApp.bundleIDCache.filter { !bundleIds.contains($0) }

            var fullPruneURLs = pruneURLs
            fullPruneURLs.append(contentsOf: cacheURLs)

            var prunedIds: [String] = []

            for url in fullPruneURLs {
                url.enumerateContents(options: [.skipsSubdirectoryDescendants]) { file, _ in
                    let bundleId = file.deletingPathExtension().lastPathComponent
                    if danglingItems.contains(bundleId) {
                        try FileManager.default.trashItem(at: file, resultingItemURL: nil)
                        prunedIds.append(bundleId)
                    }
                }
            }

            try "\(PlayApp.bundleIDCache.filter({ !Set(prunedIds).contains($0) }).joined(separator: "\n"))\n"
                .write(to: PlayApp.bundleIDCacheURL, atomically: false, encoding: .utf8)
        } catch {
            Log.shared.error(error)
        }
    }
}
