//
//  FileExtensions.swift
//  PlayCover

import AppKit
import Foundation
import UniformTypeIdentifiers

let fileMgr = FileManager.default

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
        if fileMgr.fileExists(atPath: dstURL.path) {
            try fileMgr.removeItem(at: dstURL)
        }
        try fileMgr.copyItem(at: srcURL, to: dstURL)
    }

    func filesCount(inDir: URL) throws -> Int {
        if fileMgr.fileExists(atPath: inDir.path) {
            return try fileMgr.contentsOfDirectory(atPath: inDir.path).count
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
