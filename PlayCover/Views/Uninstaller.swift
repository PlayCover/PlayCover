//
//  Uninstaller.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 9/26/22.
//

import SwiftUI

class Uninstaller {
    private static let baseURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
        .appendingPathComponent("io.playcover.PlayCover")
    private static let containerURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Containers")
    private static let pruneURLs: [URL] = [
        baseURL.appendingPathComponent("App Settings"),
        baseURL.appendingPathComponent("Entitlements"),
        baseURL.appendingPathComponent("Keymapping")
    ]

    private static func createButtonView(_ yaxis: CGFloat, _ text: String, _ state: Bool) -> (NSView, NSButton) {
        let button = NSButton(checkboxWithTitle: text, target: self, action: nil)

        if state {
            button.animator().setNextState()
        }

        let view = NSView(frame: NSRect(x: 0, y: yaxis,
                                        width: button.fittingSize.width,
                                        height: button.fittingSize.height))

        view.addSubview(button)

        return (view, button)
    }

    static func uninstallPopup(_ app: PlayApp) {
        if UninstallSettings.shared.showUninstallPopup {
            let boxmakers: [String] = [
                NSLocalizedString("alert.uninstall.removeEntitlements", comment: ""),
                NSLocalizedString("alert.uninstall.removeSetting", comment: ""),
                NSLocalizedString("alert.uninstall.removeKeymap", comment: ""),
                NSLocalizedString("alert.uninstall.clearAppData", comment: "")
            ]

            var checkboxes: [(NSView, NSButton)] = []

            var viewY = 0.0

            for buttontitle in boxmakers {
                checkboxes.append(
                    createButtonView(viewY, buttontitle, UninstallSettings.shared.getSettings(buttontitle) ?? false)
                )
                viewY += checkboxes[checkboxes.count - 1].0.frame.height
            }

            let viewWidth = checkboxes.max(by: { $0.0.frame.width < $1.0.frame.width })?.0.frame.width

            let settingsView = NSStackView(frame: NSRect(x: 0, y: 0, width: viewWidth!, height: viewY))

            for (view, _) in checkboxes {
                settingsView.addSubview(view)
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

            delete.hasDestructiveAction = true

            let response = alert.runModal()

            if response == .alertFirstButtonReturn {
                for (_, button) in checkboxes {
                    UninstallSettings.shared.setSettings(button.title, (button.state.rawValue != 0))
                }

                if alert.suppressionButton?.state == .on {
                    UninstallSettings.shared.showUninstallPopup = false
                }

                uninstall(app)
            }
        } else {
            uninstall(app)
        }
    }

    static func uninstall(_ app: PlayApp) {
        if UninstallSettings.shared.clearAppDataUninstall {
            app.container?.clear()
        }

        do {
            if UninstallSettings.shared.removeAppKeymapUninstall {
                try FileManager.default.delete(at: app.keymapping.keymapURL)
            }

            if UninstallSettings.shared.removeAppSettingUninstall {
                try FileManager.default.delete(at: app.settings.settingsUrl)
            }

            if UninstallSettings.shared.removeAppEntitlementsUninstall {
                try FileManager.default.delete(at: app.entitlements)
            }
        } catch {
            Log.shared.error(error)
        }

        app.deleteApp()
    }

    static func pruneFiles() {
        let bundleIds = AppsVM.shared.apps.map { $0.info.bundleIdentifier }

        for url in pruneURLs {
            do {
                try url.enumerateContents { file, _ in
                    if !bundleIds.contains(file.deletingPathExtension().lastPathComponent) {
                        let containerPath = containerURL.appendingPathComponent(file.deletingPathExtension()
                            .lastPathComponent)

                        if FileManager.default.fileExists(atPath: containerPath.path) {
                            try FileManager.default.delete(at: containerPath)
                        }

                        try FileManager.default.delete(at: file)
                    }
                }
            } catch {
                Log.shared.error(error)
            }
        }
    }
}
