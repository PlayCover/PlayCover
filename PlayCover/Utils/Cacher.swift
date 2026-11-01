//
//  Cacher.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 10/2/1401 AP.
//

import Foundation
import AppKit
@preconcurrency import DataCache
import CachedAsyncImage
import Synchronization
import UniformTypeIdentifiers

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

    /// Shown for apps whose bundle carries no icon, so a missing icon never looks like one still loading.
    static let placeholderIcon = NSWorkspace.shared.icon(for: .applicationBundle)

    /// The cached icon for `bundleIdentifier`, or the placeholder.
    func cachedIcon(bundleIdentifier: String) -> NSImage {
        cache.readImage(forKey: bundleIdentifier) ?? Cacher.placeholderIcon
    }

    /// Resolves the app's best icon off the main actor; it walks the bundle and parses the asset catalog.
    /// Falls back to the placeholder when the bundle has no icon.
    func resolveLocalIcon(_ app: PlayApp) async -> NSImage {
        let url = app.url
        let bundleIdentifier = app.info.bundleIdentifier
        let bundleVersion = app.info.bundleVersion
        let primaryIconName = app.info.primaryIconName
        let data = await Task.detached(priority: .utility) {
            Cacher.resolveLocalIconData(at: url, bundleIdentifier: bundleIdentifier,
                                        bundleVersion: bundleVersion, primaryIconName: primaryIconName)
        }.value
        return data.flatMap(NSImage.init(data:)) ?? Cacher.placeholderIcon
    }

    /// Cached icon for `bundleIdentifier`, or the largest icon found in the bundle (which is then cached).
    nonisolated static func resolveLocalIconData(
        at url: URL,
        bundleIdentifier: String,
        bundleVersion: String,
        primaryIconName: String
    ) -> Data? {
        let cache = DataCache.instance
        let compareStr = bundleIdentifier + bundleVersion
        if cache.readString(forKey: compareStr) != nil,
           let cachedImage = cache.readImage(forKey: bundleIdentifier) {
            return cachedImage.tiffRepresentation
        }

        let candidates = Mutex<[Data]>([])
        url.enumerateContents(blocking: true) { file, _ in
            guard file.lastPathComponent.contains(primaryIconName), let icon = NSImage(contentsOf: file),
                  let data = icon.tiffRepresentation else {
                return
            }
            candidates.withLock { $0.append(data) }
        }

        var images = candidates.withLock { $0 }.compactMap(NSImage.init(data:))
        if let assetsExtractor = try? AssetsExtractor(appUrl: url) {
            images.append(contentsOf: assetsExtractor.extractIcons())
        }
        let bestResImage = images.max { $0.size.height < $1.size.height }
        cache.write(string: compareStr, forKey: compareStr)
        if let image = bestResImage { cache.write(image: image, forKey: bundleIdentifier) }
        return cache.readImage(forKey: bundleIdentifier)?.tiffRepresentation
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
