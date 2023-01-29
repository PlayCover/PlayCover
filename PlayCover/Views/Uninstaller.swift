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
        PlayTools.playCoverContainer.appendingPathComponent("Keymapping")
    ]
    private static let otherPruneURLs: [URL] = [
        PlayApp.aliasDirectory
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

    static func uninstallPopup(_ app: PlayApp) {
        if UninstallPreferences.shared.showUninstallPopup {
            let boxmakers: [(String, String)] = [
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

            let settingsView = NSStackView(frame: NSRect(x: 0, y: 0, width: viewWidth!, height: viewY))

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

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                for checkboxhelper in checkboxes {
                    UninstallPreferences.shared.setValue(checkboxhelper.button.state == .on,
                                                         forKey: checkboxhelper.buttonvar)
                }

                if alert.suppressionButton?.state == .on {
                    UninstallPreferences.shared.showUninstallPopup = false
                }

                uninstall(app)
            }
        } else {
            uninstall(app)
        }
    }

    static func uninstall(_ app: PlayApp) {
        if UninstallPreferences.shared.clearAppData {
            app.clearAllCache()
        }

        if UninstallPreferences.shared.removeAppKeymap {
            FileManager.default.delete(at: app.keymapping.keymapURL)
        }

        if UninstallPreferences.shared.removeAppSettings {
            FileManager.default.delete(at: app.settings.settingsUrl)
        }

        if UninstallPreferences.shared.removeAppEntitlements {
            FileManager.default.delete(at: app.entitlements)
        }

        app.removeAlias()
        app.deleteApp()
    }

    static func clearExternalCache(_ bundleId: String) {
        for cache in cacheURLs {
            FileManager.default.delete(at: cache.appendingPathComponent(bundleId))
        }
    }

    static func pruneFiles() {
        let bundleIds = AppsVM.shared.filteredApps.map { $0.info.bundleIdentifier }
        let appNames = AppsVM.shared.filteredApps.map { $0.info.displayName }

        do {
            for url in pruneURLs {
                try url.enumerateContents { file, _ in
                    let bundleId = file.deletingPathExtension().lastPathComponent
                    if !bundleIds.contains(bundleId) {
                        clearExternalCache(bundleId)

                        FileManager.default.delete(at: file)
                    }
                }
            }
            for url in otherPruneURLs {
                try url.enumerateContents { file, _ in
                    let appName = file.deletingPathExtension().lastPathComponent
                    if !appNames.contains(appName) {
                        FileManager.default.delete(at: file)
                    }
                }
            }
        } catch {
            Log.shared.error(error)
        }
    }
}
