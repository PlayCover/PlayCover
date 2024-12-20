//
//  PlayPackage.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 12/19/24.
//

import UniformTypeIdentifiers

class PlayPackage {

    public static var settingsFile: String {
        "settings.plist"
    }

    public static var entitlementFile: String {
        "entitlements.plist"
    }

    public static var keymappingFile: String {
        "keymapping.plist"
    }

    private let app: PlayApp

    init(app: PlayApp) {
        self.app = app
    }

    private static func allocateTmpDir() -> URL? {
        try? FileManager.default.url(for: .itemReplacementDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: URL(fileURLWithPath: "/Users"),
                                     create: true)
    }

    private func aggregateData(tmpDirectory: URL) async throws {
        let outputAppURL = tmpDirectory.appendingEscapedPathComponent(app.url.lastPathComponent)

        try FileManager.default.copyItem(at: app.container.containerUrl,
                                         to: tmpDirectory)

        try FileManager.default.copyItem(at: app.url,
                                         to: outputAppURL)

        try FileManager.default.copyItem(at: app.settings.settingsUrl,
                                         to: tmpDirectory.appendingPathComponent(PlayPackage.settingsFile))

        try FileManager.default.copyItem(at: app.entitlements,
                                         to: tmpDirectory.appendingPathComponent(PlayPackage.entitlementFile))

        try FileManager.default.copyItem(at: app.keymapping.keymapURL,
                                         to: tmpDirectory.appendingPathComponent(PlayPackage.keymappingFile))

        await PlayTools.removeFromApp(outputAppURL.appendingEscapedPathComponent(app.info.executableName))
    }

    private func selectOutputDir(completion: @escaping (URL) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.title = NSLocalizedString("playapp.exportApp", comment: "")
        savePanel.nameFieldLabel = NSLocalizedString("playapp.exportApp.fieldLabel", comment: "")
        savePanel.nameFieldStringValue = app.info.displayName
        savePanel.allowedContentTypes = [UTType(exportedAs: "io.playcover.PlayCover-playpkg")]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false

        savePanel.begin { result in
            if result == .OK {
                if let selectedPath = savePanel.url {
                    completion(selectedPath)
                }

                savePanel.close()
            }
        }
    }

    public func zipAndExport() {
        selectOutputDir { [self] outputZipFile in
            Task(priority: .userInitiated) {
                guard let tmpDirectory = PlayPackage.allocateTmpDir() else {
                    Log.shared.error(PlayCoverError.noTmpDir)

                    return
                }

                defer {
                    FileManager.default.delete(at: tmpDirectory)

                    ExportAppVM.shared.next(.finish, 0.9, 1.0)
                }

                do {
                    ExportAppVM.shared.next(.copy, 0.0, 0.25)

                    try await aggregateData(tmpDirectory: tmpDirectory)

                    ExportAppVM.shared.next(.zip, 0.25, 75)

                    try Shell.run("/usr/bin/zip",
                                  "-r",
                                  tmpDirectory.absoluteString,
                                  outputZipFile.absoluteString)

                    ExportAppVM.shared.next(.deleteTmp, 75, 0.9)
                } catch {
                    Log.shared.error(error)
                }
            }
        }
    }

    public static func unzipToTmp(playPackage: URL) -> URL? {
        let tmpDir = PlayPackage.allocateTmpDir()

        guard let tmpDir = tmpDir else {
            return nil
        }

        do {
            try Shell.run("/usr/bin/unzip",
                          playPackage.absoluteString,
                          tmpDir.absoluteString)
        } catch {
            return nil
        }

        return tmpDir
    }

}
