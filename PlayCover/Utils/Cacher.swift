//
//  Cacher.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 10/2/1401 AP.
//

import Foundation
import AppKit
import DataCache

class Cacher {

    let cache = DataCache.instance
    /// We can create a custom cache like this (default values are as the same as below):
    /// `let cache = DataCache(name: "PlayCoverCache")`
    /// `cache.maxDiskCacheSize = 100*1024*1024`      // 100 MB
    /// `cache.maxCachePeriodInSecond = 7*86400`      // 1 week
    /// More details: https://github.com/huynguyencong/DataCache/blob/master/README.md

    func resolveITunesData(_ link: String) async {
        if let refreshedITunesData = await getITunesData(link) {
            try? cache.write(codable: refreshedITunesData, forKey: link)
        }
    }

    func resolveLocalIcon(_ app: PlayApp) -> NSImage? {
        var bestResImage: NSImage?
        let compareStr = app.info.bundleIdentifier + app.info.bundleVersion

        app.url.enumerateContents(blocking: false) { file, _ in
            if file.lastPathComponent.contains(app.info.primaryIconName), let icon = NSImage(contentsOf: file),
               self.checkImageDimensions(icon, bestResImage) {
                bestResImage = icon
            }
        }

        if let assetsExtractor = try? AssetsExtractor(appUrl: app.url) {
            for icon in assetsExtractor.extractIcons() where checkImageDimensions(icon, bestResImage) {
                bestResImage = icon
            }
        }
        cache.write(string: compareStr, forKey: compareStr)
        if let image = bestResImage {
            cache.write(image: image, forKey: app.info.bundleIdentifier)
        }
        return cache.readImage(forKey: app.info.bundleIdentifier)
    }

    func getLocalIcon(bundleId: String) -> NSImage? {
        if let app = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == bundleId }) {
            return cache.readImage(forKey: app.info.bundleIdentifier)
        } else {
            return nil
        }
    }

    private func checkImageDimensions(_ new: NSImage, _ currentBest: NSImage?) -> Bool {
        return new.size.height > currentBest?.size.height ?? -1
    }
}

extension URLCache {
    static let iconCache = URLCache(memoryCapacity: 4*1024*1024, diskCapacity: 20*1024*1024) // 4MB and 20MB
}
