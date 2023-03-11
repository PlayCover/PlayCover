//
//  FileExtensions.swift
//  PlayCover
//

import Foundation
import UniformTypeIdentifiers

extension FileManager {
    func delete(at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            } catch {
                Log.shared.error(error)
            }
        }
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
                if let url = panel.urls.first {
                    completion(.success(url))
                }
            }
        }
    }
}
