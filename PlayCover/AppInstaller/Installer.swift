//
//  Installer.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 24.11.2021.
//

import Foundation

class Installer {

    static func installPlayToolsPopup() -> Bool {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("alert.install.injectPlayToolsQuestion", comment: "")
        alert.informativeText = NSLocalizedString("alert.install.playToolsInformative", comment: "")

        alert.alertStyle = .informational

        alert.showsSuppressionButton = true
        alert.suppressionButton?.toolTip = NSLocalizedString("alert.supression", comment: "String")

        let yes = alert.addButton(withTitle: NSLocalizedString("button.Yes", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.No", comment: ""))

        // Set default button to install playtools
        yes.keyEquivalent = "\r"

        let response = alert.runModal()

        if alert.suppressionButton?.state == .on {
            InstallPreferences.shared.showInstallPopup = false
            InstallPreferences.shared.alwaysInstallPlayTools = response == .alertFirstButtonReturn
        }

        return response == .alertFirstButtonReturn
    }

    static private func returnErrorString(error: Error) -> String {
        switch error.localizedDescription {
        case let str where str.contains("(disk full?)"): NSLocalizedString("alert.notSpace", comment: "")
        case let str where str.contains(".html"): NSLocalizedString("alert.quota.limit", comment: "")
        case let str where str.contains(".ipa"): NSLocalizedString("alert.corrupted", comment: "")
        default: NSLocalizedString(error.localizedDescription, comment: "")
        }
    }

    // swiftlint:disable:next function_body_length
    static func install(ipaUrl: URL, export: Bool, returnCompletion: @escaping (URL?) -> Void) {
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

        InstallVM.shared.next(.begin, 0.0, 0.0)

        Task(priority: .userInitiated) {
            let ipa = IPA(url: ipaUrl)
            defer { ipa.releaseTempDir() }

            do {
                InstallVM.shared.next(.unzip, 0.0, 0.5)
                try ipa.allocateTempDir()

                let app = try ipa.unzip()
                if await ipa.checkOfficialMacOS(app: IPA.Application.base(app)) {
                    InstallVM.shared.next(.failed, 0.95, 1.0)
                    returnCompletion(nil)
                    return
                }
                InstallVM.shared.next(.library, 0.5, 0.55)
                try saveEntitlements(app)
                let machos = resolveValidMachOs(app)
                app.validMachOs = machos

                InstallVM.shared.next(.playtools, 0.55, 0.85)

                for macho in machos {
                    if try Macho.isMachoEncrypted(atURL: macho) {
                        throw PlayCoverError.appEncrypted
                    }

                    if !export {
                        try Macho.convertMacho(macho)
                        try Shell.signMacho(macho)
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
                InstallVM.shared.next(.wrapper, 0.85, 0.95)

                var finalURL: URL

                if export {
                    finalURL = try ipa.packIPABack(app: app.url)
                } else {
                    finalURL = try wrap(app)
                    let installedApp = PlayApp(appUrl: finalURL)

                    installedApp.sign()
                }

                try ipa.removeQuarantine(finalURL)
                InstallVM.shared.next(.finish, 0.95, 1.0)
                returnCompletion(finalURL)
            } catch {
                Log.shared.error(returnErrorString(error: error))
                InstallVM.shared.next(.failed, 0.95, 1.0)
                returnCompletion(nil)
            }
        }
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

    private static let nonMachOExtensions: Set<String> = [
        "png", "jpg", "jpeg", "webp", "gif", "svg", "ico", "icns", "heic",
        "json", "plist", "strings", "stringsdict", "nib", "storyboardc", "car",
        "ttf", "otf", "ttc", "woff", "woff2",
        "mp3", "mp4", "m4a", "mov", "wav", "caf", "aiff", "ogg", "aac",
        "html", "htm", "css", "js", "map", "txt", "md", "xml", "yaml", "yml", "pdf",
        "zip", "gz", "tar", "br", "db", "sqlite", "sqlite3",
        "cer", "der", "pem", "crt", "p12", "mobileprovision",
        "metallib", "mom", "momd", "omo", "xcprivacy", "lproj",
        "pak", "bin", "dat", "svga", "pag", "lottie", "wasm",
        "h", "m", "swift", "modulemap"
    ]

    private static let validMachOMagics: Set<[UInt8]> = [
        [0xCA, 0xFE, 0xBA, 0xBE],
        [0xBE, 0xBA, 0xFE, 0xCA],
        [0xCA, 0xFE, 0xBA, 0xBF],
        [0xBF, 0xBA, 0xFE, 0xCA],
        [0xCF, 0xFA, 0xED, 0xFE],
        [0xFE, 0xED, 0xFA, 0xCF]
    ]

    private static func isValidMachOFile(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }

        defer {
            do {
                try handle.close()
            } catch {
                print("Failed to close FileHandle for \(url.absoluteString): \(error.localizedDescription)")
            }
        }

        guard let data = try? handle.read(upToCount: 4), data.count == 4 else {
            return false
        }

        return validMachOMagics.contains(Array(data))
    }

    /// Returns an array of URLs to MachO files within the app
    static func resolveValidMachOs(_ baseApp: BaseApp) -> [URL] {
        if let validMachOs = baseApp.validMachOs {
            return validMachOs
        }

        var resolved: [URL] = []
        var seen: Set<URL> = []

        let executableURL = baseApp.executable
        if let execAttrs = try? executableURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
           execAttrs.isRegularFile == true,
           let fileSize = execAttrs.fileSize,
           fileSize > 4,
           isValidMachOFile(executableURL) {
            seen.insert(executableURL.standardizedFileURL)
            resolved.append(executableURL)
        }

        // Metadata enumeration is cheap local I/O. Scheduling an Operation for every
        // asset and serializing results added thousands of tasks to otherwise warm launches.
        // Keep the same package boundaries: frameworks belong to the host, app extensions
        // and component bundles retain their independent platform and signing identity.
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .isDirectoryKey, .isPackageKey]
        if let enumerator = FileManager.default.enumerator(at: baseApp.url,
                                                           includingPropertiesForKeys: Array(keys),
                                                           options: [.skipsHiddenFiles]) {
            for case let url as URL in enumerator {
                let ext = url.pathExtension.lowercased()
                // Directory URLs from FileManager carry the directory bit. Skip obvious
                // resource files before asking Foundation to bridge their full metadata.
                if !url.hasDirectoryPath, nonMachOExtensions.contains(ext) { continue }
                guard let attributes = try? url.resourceValues(forKeys: keys) else { continue }
                if attributes.isDirectory == true,
                   attributes.isPackage == true || ["appex", "bundle"].contains(ext), ext != "framework" {
                    enumerator.skipDescendants()
                }
                guard attributes.isRegularFile == true, let size = attributes.fileSize, size > 4,
                      !nonMachOExtensions.contains(ext), isValidMachOFile(url) else { continue }
                if seen.insert(url.standardizedFileURL).inserted { resolved.append(url) }
            }
        }
        baseApp.validMachOs = resolved
        return resolved
    }

    /// Wrapper for codesign, applies the given entitlements to the application and all of its contents
    static func saveEntitlements(_ baseApp: BaseApp) throws {
        let toSave = try Entitlements.dumpEntitlements(exec: baseApp.executable)
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
