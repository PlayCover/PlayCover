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
            let screenshots: [String]
            let screenshotsArrayName = refreshedITunesData.results[0].bundleId + ".scUrls"
            do {
                try cache.write(codable: refreshedITunesData, forKey: link)
                if refreshedITunesData.results[0].ipadScreenshotUrls.isEmpty {
                    screenshots = refreshedITunesData.results[0].screenshotUrls
                } else {
                    screenshots = refreshedITunesData.results[0].ipadScreenshotUrls
                }
                cache.write(array: screenshots, forKey: screenshotsArrayName)
            } catch {
                print("Write error \(error.localizedDescription)")
            }
        }
    }

    func resolveLocalIcon(_ app: PlayApp) async -> NSImage? {
        var appIcon: NSImage?
        let compareStr = app.info.bundleIdentifier + app.info.bundleVersion
        if cache.readImage(forKey: app.info.bundleIdentifier) != nil
            && cache.readString(forKey: compareStr) != nil {
            if let image = cache.readImage(forKey: app.info.bundleIdentifier) {
                appIcon = image
            }
        } else {
            var bestResImage: NSImage?
            if let assetsExtractor = try? AssetsExtractor(appUrl: app.url) {
                for icon in assetsExtractor.extractIcons() where checkImageDimensions(icon, bestResImage) {
                    bestResImage = icon
                }
            }
            cache.write(string: compareStr, forKey: compareStr)
            cache.write(image: bestResImage!, forKey: app.info.bundleIdentifier)
            appIcon = cache.readImage(forKey: app.info.bundleIdentifier)
        }
        return appIcon
    }

    func getLocalIcon(bundleId: String) async -> NSImage? {
        if let app = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == bundleId }) {
            return await resolveLocalIcon(app)
        } else {
            return nil
        }
    }

    private func checkImageDimensions(_ new: NSImage, _ currentBest: NSImage?) -> Bool {
        return new.size.height > currentBest?.size.height ?? -1
    }
}

/// Spliting cache instance in URLCache for Online App Icons and Online Screenshots to be used in CachedAsyncImage
extension URLCache {
    static let iconCache = URLCache(memoryCapacity: 4*1024*1024, diskCapacity: 20*1024*1024) // 4MB and 20MB
    static let screenshotCache = URLCache(memoryCapacity: 4*1024*1024, diskCapacity: 30*1024*1024) // 4MB and 30MB
}
/// If we don't split it, screenshots exceed `URLCache.shared` capacity too often and it purges itself
/// We may want to screenshots be purged but app icons should not be purged this often
/// Usage of this extension in CachedAsyncImage is like
/// `CachedAsyncImage(url: url, urlCache: .cacheName)`
/// If any more instances has been added in future remember to add:
/// `URLCache.cacheName.removeAllCachedResponses()`
/// In `MenuBarView` for clearing its cache on user request
