//
//  FileExtensions.swift
//  PlayCover

import AppKit
import Foundation
import UniformTypeIdentifiers

extension FileManager {
    func delete(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            } catch {
                Log.shared.error(error)
            }
        }
    }

    func copy(at srcURL: URL, to dstURL: URL) throws {
        if FileManager.default.fileExists(atPath: dstURL.path) {
            try FileManager.default.removeItem(at: dstURL)
        }
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
    }

    func filesCount(inDir: URL) throws -> Int {
        if FileManager.default.fileExists(atPath: inDir.path) {
            return try FileManager.default.contentsOfDirectory(atPath: inDir.path).count
        }
        return 0
    }
}

extension NSOpenPanel {

    static func selectIPA(completion: @escaping (_ result: Result<URL, Error>) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType(importedAs: "com.apple.itunes.ipa")]
        panel.canChooseFiles = true
        panel.begin { result in
            if result == .OK {
                let url = panel.urls.first
                completion(.success(url!))
            }
        }
    }
}
