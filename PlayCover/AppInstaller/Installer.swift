//
//  Installer.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 24.11.2021.
//

import Foundation

class Installer {

    static func install(ipaUrl: URL, returnCompletion: @escaping (URL?) -> Void) {
        InstallVM.shared.next(.begin, 0.0, 0.0)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let ipa = IPA(url: ipaUrl)
                InstallVM.shared.next(.unzip, 0.0, 0.5)
                let app = try ipa.unzip()
                InstallVM.shared.next(.library, 0.5, 0.55)
                try saveEntitlements(app)
                let machos = try resolveValidMachOs(app)
                app.validMachOs = machos

                InstallVM.shared.next(.playtools, 0.55, 0.85)
                try PlayTools.installInIPA(app.executable, app.url, resign: true)

                for macho in machos {
                    if try PlayTools.isMachoEncrypted(atURL: macho) {
                        throw PlayCoverError.appEncrypted
                    }
                    try PlayTools.replaceLibraries(atURL: macho)
                    try PlayTools.convertMacho(macho)
                    try fakesign(macho)
                }

                // -rwxr-xr-x
                try app.executable.setBinaryPosixPermissions(0o755)

                try removeMobileProvision(app)

                let info = app.info

                info.assert(minimumVersion: 11.0)
                try info.write()

                InstallVM.shared.next(.wrapper, 0.85, 0.95)

                let installed = try wrap(app)
                let installedApp = PlayApp(appUrl: installed)
                try PlayTools.installPluginInIPA(installedApp.url)
                installedApp.sign()
                try ipa.releaseTempDir()
                InstallVM.shared.next(.finish, 0.95, 1.0)
                returnCompletion(installed)
            } catch {
                Log.shared.error(error)
                InstallVM.shared.next(.finish, 0.95, 1.0)
                returnCompletion(nil)
            }
        }
    }

    static func exportForSideloadly(ipaUrl: URL, returnCompletion: @escaping (URL?) -> Void) {
        InstallVM.shared.next(.begin, 0.0, 0.0)

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let ipa = IPA(url: ipaUrl)
                InstallVM.shared.next(.unzip, 0.0, 0.5)
                let app = try ipa.unzip()
                InstallVM.shared.next(.library, 0.5, 0.55)
                try saveEntitlements(app)
                let machos = try resolveValidMachOs(app)
                app.validMachOs = machos

                InstallVM.shared.next(.playtools, 0.55, 0.85)
                try PlayTools.injectInIPA(app.executable, payload: app.url)

                for macho in machos where try PlayTools.isMachoEncrypted(atURL: macho) {
                    throw PlayCoverError.appEncrypted
                }

                let info = app.info

                info.assert(minimumVersion: 11.0)
                try info.write()

                InstallVM.shared.next(.wrapper, 0.85, 0.95)

                let exported = try ipa.packIPABack(app: app.url)
                try ipa.releaseTempDir()
                InstallVM.shared.next(.finish, 0.95, 1.0)
                returnCompletion(exported)
            } catch {
                Log.shared.error(error)
                InstallVM.shared.next(.finish, 0.95, 1.0)
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

            let entryURL = folderURL.appendingPathComponent(entry)
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
    static func resolveValidMachOs(_ baseApp: BaseApp) throws -> [URL] {
        if let validMachOs = baseApp.validMachOs {
            return validMachOs
        }

        var resolved: [URL] = []

        try baseApp.url.enumerateContents { url, attributes in
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
            case [202, 254, 186, 190]: resolved.append(url)
            case [207, 250, 237, 254]: resolved.append(url)
            default: return
            }
        }

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
        let location = PlayTools.playCoverContainer.appendingPathComponent(baseApp.url.lastPathComponent)
        if FileManager.default.fileExists(atPath: location.path) {
            try FileManager.default.removeItem(at: location)
        }

        try FileManager.default.moveItem(at: baseApp.url, to: location)
        return location
    }

    /// Regular codesign, does not accept entitlements. Used to re-seal an app after you've modified it.
    static func fakesign(_ url: URL) throws {
        try shell.shello("/usr/bin/codesign", "-fs-", url.path)
    }
}
