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
        if cache.readString(forKey: app.info.bundleVersion) == app.info.bundleVersion
            && cache.readImage(forKey: app.info.bundleIdentifier) != nil {
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
            cache.write(string: app.info.bundleVersion, forKey: app.info.bundleVersion)
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
