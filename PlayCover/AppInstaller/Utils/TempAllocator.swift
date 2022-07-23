//
//  SideloadIO.swift
//  PlayCover
//

import Foundation

internal class TempAllocator {

    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PlayCoverInstall")
    }

    static func clearTemp() {
        do {
            try fileMgr.delete(at: documentDirectory)
        } catch {
            Log.shared.error(error)
        }
    }

    static var tempDirectory: URL {
        documentDirectory.appendingPathComponent("tmp")
    }

    static func allocateTempDirectory() throws -> URL {
        let workDir = TempAllocator.tempDirectory.appendingPathComponent(UUID().uuidString)

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true, attributes: [:])

        return workDir
    }

    static func allocatePayloadDirectory(tempDir: URL, app: URL) throws -> URL {
        let workDir = tempDir.appendingPathComponent("Payload")

        if FileManager.default.fileExists(atPath: workDir.path) {
            try FileManager.default.delete(at: workDir)
        }

        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true, attributes: [:])

        try FileManager.default.moveItem(at: app, to: workDir)
        return workDir
    }
}
