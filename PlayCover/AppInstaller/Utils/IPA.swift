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
        if let workDir = tempDir, FileManager.default.fileExists(atPath: workDir.path) {
            return workDir
        }

        let workDir = try TempAllocator.allocateTempDirectory()
        tempDir = workDir

        return workDir
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

    public func unzip() throws -> BaseApp {
        let workDir = try allocateTempDir()

        if Shell.quietUnzip(url, toUrl: workDir) == "" {
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
