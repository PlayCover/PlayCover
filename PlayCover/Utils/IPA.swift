//
//  IPA.swift
//  PlayCover
//

import Foundation

public class IPA {
    public let url: URL
    public private(set) var tmpDir: URL?

    public init(url: URL) {
        self.url = url
    }

    public func allocateTempDir() throws {
        tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: URL(fileURLWithPath: "/Users"),
                                             create: true)
    }

    public func releaseTempDir() {
        guard let workDir = tmpDir else {
            return
        }

        FileManager.default.delete(at: workDir)

        tmpDir = nil
    }

    public func removeQuarantine(_ execUrl: URL) throws {
        try Shell.run("/usr/bin/xattr", "-r", "-d", "com.apple.quarantine", execUrl.relativePath)
    }

    public func unzip() throws -> BaseApp {
        if let workDir = tmpDir {
            if try Shell.run("/usr/bin/unzip",
                             "-oq", url.path, "-d", workDir.path) == "" {
                return try Installer.fromIPA(detectingAppNameInFolder: workDir.appendingPathComponent("Payload"))
            } else {
                throw PlayCoverError.appCorrupted
            }
        } else {
            throw PlayCoverError.appCorrupted
        }
    }

    func packIPABack(app: URL) throws -> URL {
        let payload = app.deletingPathExtension().deletingLastPathComponent()
        let name = app.deletingPathExtension().lastPathComponent

        let newIpa = getDocumentsDirectory()
            .appendingEscapedPathComponent(name)
            .appendingPathExtension("ipa")

        try Shell.run("usr/bin/zip", "-r", newIpa.path, payload.path)

        return newIpa
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
}
