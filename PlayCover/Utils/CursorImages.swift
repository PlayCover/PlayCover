//
//  CursorImages.swift
//  PlayCover
//  
//  Created by viatearz on 2025/2/12.
//

import Foundation

class CursorImages {
    static let shared = CursorImages()
    static var cursorImageDir: URL {
        let cursorImageFolder = PlayTools.playCoverContainer.appendingPathComponent("Cursors")

        if !FileManager.default.fileExists(atPath: cursorImageFolder.path) {
            do {
                try FileManager.default.createDirectory(at: cursorImageFolder, withIntermediateDirectories: true)
            } catch {
                Log.shared.error(error)
            }
        }

        return cursorImageFolder
    }

    func imageURL(for bundleIdentifier: String) -> URL {
        return CursorImages.cursorImageDir
            .appendingPathComponent(bundleIdentifier)
            .appendingPathExtension("png")
    }

    func load(bundleId: String) -> NSImage? {
        let url = imageURL(for: bundleId)
        return NSImage(contentsOfFile: url.path)
    }

    func save(srcImageUrl: URL, for bundleId: String) {
        do {
            let dstImageUrl = imageURL(for: bundleId)
            FileManager.default.delete(at: dstImageUrl)
            try FileManager.default.copyItem(at: srcImageUrl, to: dstImageUrl)
        } catch {
            Log.shared.error(error)
        }
    }

    func clear(bundleId: String) {
        let url = imageURL(for: bundleId)
        FileManager.default.delete(at: url)
    }
}
