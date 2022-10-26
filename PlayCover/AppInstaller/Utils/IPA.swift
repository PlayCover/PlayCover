//
//  IPA.swift
//  PlayCover
//

import Foundation

public class IPA {

    public let url: URL
    public private(set) var tempDir: URL?

    public init(url: URL) {
        self.url = url
    }

    public func allocateTempDir() throws -> URL {
        let tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: URL(fileURLWithPath: "/Users"),
                                                 create: true)
        return tmpDir
            .appendingPathComponent(ProcessInfo().globallyUniqueString)
    }

    public func releaseTempDir() throws {
        guard let workDir = tempDir else {
            return
        }

        if FileManager.default.fileExists(atPath: workDir.path) {
            try FileManager.default.removeItem(at: workDir)
        }

        tempDir = nil
    }

    func removeQuarantine(_ execUrl: URL) throws {
        try shell.shello("/usr/bin/xattr", "-r", "-d", "com.apple.quarantine", execUrl.relativePath)
    }

    public func unzip() throws -> BaseApp {
        let workDir = try allocateTempDir()

        if Shell.quietUnzip(url, toUrl: workDir) == "" {
            try removeQuarantine(workDir)
            return try Installer.fromIPA(detectingAppNameInFolder: workDir.appendingPathComponent("Payload"))
        } else {
            throw PlayCoverError.appCorrupted
        }
    }

    func packIPABack(app: URL) throws -> URL {
        let newIpa = getDocumentsDirectory()
            .appendingPathComponent(app.deletingPathExtension().lastPathComponent).appendingPathExtension("ipa")
        try Shell.zip(
            ipa: newIpa,
            name: app.deletingPathExtension().lastPathComponent,
            payload: app.deletingLastPathComponent().deletingLastPathComponent())
        return newIpa
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
