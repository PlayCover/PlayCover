//
//  Uninstaller.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 9/26/22.
//

import SwiftUI
import Synchronization

struct CheckBoxHelper {
    var view: NSView
    var button: NSButton
    var keyPath: ReferenceWritableKeyPath<UninstallPreferences, Bool>
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

    private static func createButtonView(_ yaxis: CGFloat, _ text: String,
                                         _ keyPath: ReferenceWritableKeyPath<UninstallPreferences, Bool>)
        -> CheckBoxHelper {
        let button = NSButton(checkboxWithTitle: text, target: self, action: nil)

        if UninstallPreferences.shared[keyPath: keyPath] {
            button.animator().setNextState()
        }

        let view = NSView(frame: NSRect(x: 0, y: yaxis,
                                        width: button.fittingSize.width,
                                        height: button.fittingSize.height))

        view.addSubview(button)

        return CheckBoxHelper(view: view, button: button, keyPath: keyPath)
    }

    @MainActor
    static func uninstallPopup(_ app: PlayApp) async {
        if UninstallPreferences.shared.showUninstallPopup {
            var checkboxes: [CheckBoxHelper] = []

            var viewY = 0.0

            // AppKit's y axis grows upward, so the bottom row is laid out first.
            for option in UninstallPreferences.cleanupOptions.reversed() {
                checkboxes.append(createButtonView(viewY, NSLocalizedString(option.title, comment: ""),
                                                   option.keyPath))
                viewY += checkboxes[checkboxes.count - 1].view.frame.height
            }

            let viewWidth = checkboxes.max(by: { $0.view.frame.width < $1.view.frame.width })?.view.frame.width

            let settingsView = NSStackView(frame: NSRect(x: 0, y: 0, width: viewWidth ?? 0, height: viewY))

            for checkboxhelper in checkboxes {
                settingsView.addSubview(checkboxhelper.view)
            }

            let response = await AlertPresenter.shared.present(AlertRequest(
                title: NSLocalizedString("playapp.delete", comment: ""),
                message: String(format: NSLocalizedString("playapp.deleteMessage", comment: ""),
                                arguments: [app.name]),
                style: .warning,
                buttons: [.localized("playapp.deleteConfirm", isDestructive: true), .localized("button.Cancel")],
                suppressionTooltip: NSLocalizedString("alert.supression", comment: ""),
                accessoryView: settingsView,
                asSheet: true,
                requestsAttention: true
            ))
            guard response.isFirstButton else { return }
            for checkboxhelper in checkboxes {
                UninstallPreferences.shared[keyPath: checkboxhelper.keyPath] = checkboxhelper.button.state == .on
            }

            if response.isSuppressed {
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
            FileManager.default.delete(at: app.keymapping.baseKeymapURL)
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
            let url = KeyCover.playChainPath.appendingPathComponent(app.info.bundleIdentifier)
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
        let response = await AlertPresenter.shared.present(AlertRequest(
            title: NSLocalizedString("alert.app.delete", comment: ""),
            style: .warning,
            buttons: [.localized("button.Proceed", isDestructive: true), .localized("button.Cancel")],
            asSheet: true,
            requestsAttention: true
        ))
        guard response.isFirstButton else { return }

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

            let prunedIds = Mutex<[String]>([])

            for url in fullPruneURLs {
                url.enumerateContents(options: [.skipsSubdirectoryDescendants]) { file, _ in
                    let bundleId = file.deletingPathExtension().lastPathComponent
                    if danglingItems.contains(bundleId) {
                        try FileManager.default.trashItem(at: file, resultingItemURL: nil)
                        prunedIds.withLock { $0.append(bundleId) }
                    }
                }
            }

            let pruned = prunedIds.withLock { $0 }
            try "\(PlayApp.bundleIDCache.filter({ !Set(pruned).contains($0) }).joined(separator: "\n"))\n"
                .write(to: PlayApp.bundleIDCacheURL, atomically: false, encoding: .utf8)
        } catch {
            Log.shared.error(error)
        }
    }
}
