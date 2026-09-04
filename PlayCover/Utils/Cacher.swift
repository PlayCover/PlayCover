//
//  Cacher.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 10/2/1401 AP.
//

import Foundation
import AppKit
import DataCache
import CachedAsyncImage

class Cacher {
    static let shared = Cacher()
    @ImageCache private var imageCache
    let cache = DataCache.instance
    /// We can create a custom cache like this (default values are as the same as below):
    /// `let cache = DataCache(name: "PlayCoverCache")`
    /// `cache.maxDiskCacheSize = 100*1024*1024`      // 100 MB
    /// `cache.maxCachePeriodInSecond = 7*86400`      // 1 week
    /// More details: https://github.com/huynguyencong/DataCache/blob/master/README.md

    init() {
        // Set image cache limit.
        ImageCache().wrappedValue.setCacheLimit(
            countLimit: 400,
            totalCostLimit: 4*1024*1024
        )
    }

    func removeImageCache() {
        imageCache.removeCache()
    }

    func resolveITunesData(_ link: String) async {
        if let refreshedITunesData = await getITunesData(link) {
            try? cache.write(codable: refreshedITunesData, forKey: link)
        }
    }

    func resolveLocalIcon(_ app: PlayApp) -> NSImage? {
        resolveLocalIcon(
            at: app.url,
            bundleIdentifier: app.info.bundleIdentifier,
            bundleVersion: app.info.bundleVersion,
            primaryIconName: app.info.primaryIconName
        )
    }

    func resolveLocalIcon(
        at url: URL,
        bundleIdentifier: String,
        bundleVersion: String,
        primaryIconName: String
    ) -> NSImage? {
        let compareStr = bundleIdentifier + bundleVersion
        if cache.readString(forKey: compareStr) != nil,
           let cachedImage = cache.readImage(forKey: bundleIdentifier) {
            return cachedImage
        }

        let lock = NSLock()
        var candidates: [NSImage] = []
        url.enumerateContents(blocking: true) { file, _ in
            guard file.lastPathComponent.contains(primaryIconName), let icon = NSImage(contentsOf: file) else {
                return
            }
            lock.lock()
            candidates.append(icon)
            lock.unlock()
        }

        if let assetsExtractor = try? AssetsExtractor(appUrl: url) {
            candidates.append(contentsOf: assetsExtractor.extractIcons())
        }
        let bestResImage = candidates.max { $0.size.height < $1.size.height }
        cache.write(string: compareStr, forKey: compareStr)
        if let image = bestResImage { cache.write(image: image, forKey: bundleIdentifier) }
        return cache.readImage(forKey: bundleIdentifier)
    }

    func resolveLocalIconData(
        at url: URL,
        bundleIdentifier: String,
        bundleVersion: String,
        primaryIconName: String
    ) -> Data? {
        resolveLocalIcon(
            at: url,
            bundleIdentifier: bundleIdentifier,
            bundleVersion: bundleVersion,
            primaryIconName: primaryIconName
        )?.tiffRepresentation
    }

    func getLocalIcon(bundleId: String) -> NSImage? {
        if let app = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == bundleId }) {
            return cache.readImage(forKey: app.info.bundleIdentifier)
        } else {
            return nil
        }
    }

}

extension URLCache {
    static let iconCache = URLCache(memoryCapacity: 4*1024*1024, diskCapacity: 20*1024*1024) // 4MB and 20MB
}
