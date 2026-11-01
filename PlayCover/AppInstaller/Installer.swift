//
//  Installer.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 24.11.2021.
//

import Foundation
import Synchronization

nonisolated enum Installer {

    @MainActor
    static func installPlayToolsPopup() -> Bool {
        let response = AlertPresenter.shared.presentModal(AlertRequest(
            title: NSLocalizedString("alert.install.injectPlayToolsQuestion", comment: ""),
            message: NSLocalizedString("alert.install.playToolsInformative", comment: ""),
            buttons: [.localized("button.Yes", isDefault: true), .localized("button.No")],
            suppressionTooltip: NSLocalizedString("alert.supression", comment: "String")
        ))

        if response.isSuppressed {
            InstallPreferences.shared.showInstallPopup = false
            InstallPreferences.shared.alwaysInstallPlayTools = response.isFirstButton
        }

        return response.isFirstButton
    }

    static private func returnErrorString(error: Error) -> String {
        switch error.localizedDescription {
        case let str where str.contains("(disk full?)"): NSLocalizedString("alert.notSpace", comment: "")
        case let str where str.contains(".html"): NSLocalizedString("alert.quota.limit", comment: "")
        case let str where str.contains(".ipa"): NSLocalizedString("alert.corrupted", comment: "")
        default: NSLocalizedString(error.localizedDescription, comment: "")
        }
    }

    @MainActor static func install(ipaUrl: URL, export: Bool,
                                   returnCompletion: @escaping @Sendable (URL?) -> Void) {
        // If (the option key is held or the install playtools popup settings is true) and its not an export,
        //    then show the installer dialog
        let installPlayTools: Bool
        let applicationType = InstallPreferences.shared.defaultAppType

        if (ModifierKeyObserver.shared.isOptionKeyPressed
                || InstallPreferences.shared.showInstallPopup) && !export {
            installPlayTools = installPlayToolsPopup()
        } else {
            installPlayTools = InstallPreferences.shared.alwaysInstallPlayTools
        }

        let (updates, progress) = AsyncStream.makeStream(of: InstallVM.Update.self)
        InstallVM.shared.track(updates)
        progress.yield(.init(.begin, 0.0, 0.0))

        // Detached so unzip / codesign stay off the main actor after the UI prompt returns.
        Task.detached(priority: .userInitiated) {
            defer { progress.finish() }
            do {
                let finalURL = try await runPipeline(ipaUrl: ipaUrl, export: export,
                                                     installPlayTools: installPlayTools,
                                                     applicationType: applicationType,
                                                     progress: progress)
                progress.yield(.init(finalURL == nil ? .failed : .finish, 0.95, 1.0))
                await MainActor.run { returnCompletion(finalURL) }
            } catch {
                let message = returnErrorString(error: error)
                progress.yield(.init(.failed, 0.95, 1.0))
                await MainActor.run {
                    Log.shared.error(message)
                    returnCompletion(nil)
                }
            }
        }
    }

    /// Unzip, convert, inject and wrap. Returns `nil` when the user chose the App Store version instead.
    private static func runPipeline(ipaUrl: URL, export: Bool, installPlayTools: Bool,
                                    applicationType: LSApplicationCategoryType,
                                    progress: AsyncStream<InstallVM.Update>.Continuation) async throws -> URL? {
        let ipa = IPA(url: ipaUrl)
        defer { ipa.releaseTempDir() }

        progress.yield(.init(.unzip, 0.0, 0.5))
        try ipa.allocateTempDir()

        let app = try ipa.unzip()
        if await ipa.checkOfficialMacOS(app: IPA.Application.base(app)) {
            return nil
        }
        progress.yield(.init(.library, 0.5, 0.55))
        try await saveEntitlements(app)
        let machos = resolveValidMachOs(app)
        app.validMachOs = machos

        progress.yield(.init(.playtools, 0.55, 0.85))

        for macho in machos {
            if try Macho.isMachoEncrypted(atURL: macho) {
                throw PlayCoverError.appEncrypted
            }

            if !export {
                try Macho.convertMacho(macho)
                try await Shell.signMacho(macho)
            }
        }

        if export {
            try PlayTools.injectInIPA(app.executable, payload: app.url)
        } else if installPlayTools {
            try await PlayTools.installInIPA(app.executable)
        }

        app.info.applicationCategoryType = applicationType

        if !export {
            // -rwxr-xr-x
            try app.executable.setBinaryPosixPermissions(0o755)
            try removeMobileProvision(app)
        }

        let info = app.info
        info.assert(minimumVersion: 11.0)
        try info.write()
        progress.yield(.init(.wrapper, 0.85, 0.95))

        let finalURL: URL
        if export {
            finalURL = try ipa.packIPABack(app: app.url)
        } else {
            finalURL = try wrap(app)
            let installed = await MainActor.run { PlayApp(appUrl: finalURL) }
            await AppSigner.sign(installed)
        }

        try ipa.removeQuarantine(finalURL)
        return finalURL
    }

    static func fromIPA(detectingAppNameInFolder folderURL: URL) throws -> BaseApp {
        let contents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)

        var url: URL?

        for entry in contents {
            guard entry.hasSuffix(".app") else {
                continue
            }

            let entryURL = folderURL.appendingEscapedPathComponent(entry)
            var isDirectory: ObjCBool = false

            guard FileManager.default.fileExists(atPath: entryURL.path, isDirectory: &isDirectory),
                  isDirectory.boolValue else {
                continue
            }

            url = entryURL
            break
        }

        guard let url = url else {
            throw PlayCoverError.infoPlistNotFound
        }

        return BaseApp(appUrl: url)
    }

    /// Returns an array of URLs to MachO files within the app
    static func resolveValidMachOs(_ baseApp: BaseApp) -> [URL] {
        if let validMachOs = baseApp.validMachOs {
            return validMachOs
        }

        let resolved = Mutex<[URL]>([])

        baseApp.url.enumerateContents { url, attributes in
            guard attributes.isRegularFile == true, let fileSize = attributes.fileSize, fileSize > 4 else {
                return
            }

            if !url.pathExtension.isEmpty && url.pathExtension != "dylib" {
                return
            }

            let handle = try FileHandle(forReadingFrom: url)

            defer {
                do {
                    try handle.close()
                } catch {
                    print("Failed to close FileHandle for \(url.absoluteString): \(error.localizedDescription)")
                }
            }

            guard let data = try handle.read(upToCount: 4) else {
                return
            }

            switch Array(data) {
            case [202, 254, 186, 190], [207, 250, 237, 254]:
                resolved.withLock { $0.append(url) }
            default:
                return
            }
        }

        return resolved.withLock { $0 }
    }

    /// Wrapper for codesign, applies the given entitlements to the application and all of its contents
    static func saveEntitlements(_ baseApp: BaseApp) async throws {
        let toSave = try await Entitlements.dumpEntitlements(exec: baseApp.executable)
        try toSave.store(baseApp.entitlements)
    }

    static func removeMobileProvision(_ baseApp: BaseApp) throws {
        let provision = baseApp.url.appendingPathComponent("embedded.mobileprovision")
        if FileManager.default.fileExists(atPath: provision.path) {
            try FileManager.default.removeItem(at: provision)
        }
    }

    /// Generates a wrapper bundle for an iOS app that allows it to be launched from Finder and other macOS UIs
    static func wrap(_ baseApp: BaseApp) throws -> URL {
        let info = AppInfo(contentsOf: baseApp.url
            .appendingPathComponent("Info")
            .appendingPathExtension("plist"))
        let location = AppsVM.appDirectory
            .appendingEscapedPathComponent(info.bundleIdentifier)
            .appendingPathExtension("app")
        if FileManager.default.fileExists(atPath: location.path) {
            try FileManager.default.removeItem(at: location)
        }

        try FileManager.default.moveItem(at: baseApp.url, to: location)
        return location
    }
}
