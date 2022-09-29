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
        }x
}
