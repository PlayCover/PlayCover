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

    func resolveITunesData(_ link: String) async {
        if let refreshedITunesData = await getITunesData(link) {
            let screenshots: [String]
            let screenshotsArrayName = refreshedITunesData.results[0].bundleId + "scUrls"
            do {
                try DataCache.instance.write(codable: refreshedITunesData, forKey: link)
                if refreshedITunesData.results[0].ipadScreenshotUrls.isEmpty {
                    screenshots = refreshedITunesData.results[0].screenshotUrls
                } else {
                    screenshots = refreshedITunesData.results[0].ipadScreenshotUrls
                }
                DataCache.instance.write(array: screenshots, forKey: screenshotsArrayName)
            } catch {
                print("Write error \(error.localizedDescription)")
            }
        }
    }

    func resolveLocalIcon(_ app: PlayApp) async -> NSImage? {
        if let image = DataCache.instance.readImage(forKey: app.info.bundleIdentifier) {
            return image
        } else {
            var bestResImage: NSImage?
            if let assetsExtractor = try? AssetsExtractor(appUrl: app.url) {
                for icon in assetsExtractor.extractIcons() where checkImageDimensions(icon, bestResImage) {
                    bestResImage = icon
                }
            }
            DataCache.instance.write(image: bestResImage!, forKey: app.info.bundleIdentifier)
            return DataCache.instance.readImage(forKey: app.info.bundleIdentifier)
        }
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
