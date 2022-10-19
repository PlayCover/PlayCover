//
//  ImageCache.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 17/10/2022.
//

import Foundation

class ImageCache {
    static let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        .appendingPathComponent(Bundle.main.bundleIdentifier!)
        .appendingPathComponent("Image Cache")

    static func getLocalImageURL(bundleID: String, bundleURL: URL, primaryIconName: String) -> URL? {
        // If cached icon for bundle id exists, skip getting it again
        if let cacheImageURL = getImageURLFromCache(bundleId: bundleID) {
            return cacheImageURL
        }

        var bestResImage: NSImage?

        // Failed to find icon in app bundle checking in assets
        if let assetsExtractor = try? AssetsExtractor(appUrl: bundleURL) {
            for icon in assetsExtractor.extractIcons() where checkImageDimensions(icon, bestResImage) {
                bestResImage = icon
            }
        }

        // Found icon in .car file
        if bestResImage != nil {
            return saveImageToCache(image: bestResImage!, bundleID: bundleID)
        }

        // Failed to find any icon
        return nil
    }

    static func getOnlineImageURL(bundleID: String, itunesLookup: String) async -> URL? {
        if let cacheImageURL = getImageURLFromCache(bundleId: bundleID) {
            return cacheImageURL
        }

        let itunesData = await getITunesData(itunesLookup)
        var bestImageURL: URL?

        if itunesData != nil {
            bestImageURL = URL(string: itunesData!.results[0].artworkUrl512)
        }

        if bestImageURL != nil {
            let data = try? Data(contentsOf: bestImageURL!)
            let image = NSImage(data: data!)!
            return saveImageToCache(image: image, bundleID: bundleID)
        }

        return nil
    }

    static func getITunesData(_ itunesLookup: String) async -> ITunesResponse? {
        if !NetworkVM.isConnectedToNetwork() { return nil }
        guard let url = URL(string: itunesLookup) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let decoder = JSONDecoder()
            let jsonResult: ITunesResponse = try decoder.decode(ITunesResponse.self, from: data)
            if jsonResult.resultCount > 0 {
                return jsonResult
            }
        } catch {
            print("Error getting iTunes data from URL: \(itunesLookup): \(error)")
        }

        return nil
    }

    static func getImageURLFromCache(bundleId: String) -> URL? {
        // If app is installed, try to get icon from .app bundle
        if let app = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == bundleId }) {
            var bestResImage: NSImage?
            var bestResImageURL: URL?

            do {
                let items = try FileManager.default.contentsOfDirectory(at: app.url, includingPropertiesForKeys: nil)

                for item in items where item.path.contains(app.info.primaryIconName) {
                    do {
                        if let image = NSImage(data: try Data(contentsOf: item)) {
                            if checkImageDimensions(image, bestResImage) {
                                bestResImage = image
                                bestResImageURL = item
                            }
                        }
                    }
                }
            } catch {
                Log.shared.error(error)
            }

            if bestResImageURL != nil {
                return bestResImageURL
            }
        }

        // App isn't installed or icon couldn't be found, check cache
        let imageURL = cacheFolder
            .appendingPathComponent(bundleId)
            .appendingPathExtension("png")
        if FileManager.default.fileExists(atPath: imageURL.path) {
            return imageURL
        } else {
            return nil
        }
    }

    static func saveImageToCache(image: NSImage, bundleID: String) -> URL {
        if !FileManager.default.fileExists(atPath: cacheFolder.path) {
            do {
                // If no cache directory exists, create one
                try FileManager.default.createDirectory(at: cacheFolder,
                                                        withIntermediateDirectories: true,
                                                        attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }

        let cacheURL = cacheFolder
            .appendingPathComponent(bundleID)
            .appendingPathExtension("png")

        // If a cached image for this bundle id exists, remove it
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            do {
                try FileManager.default.removeItem(at: cacheURL)
            } catch {
                Log.shared.error(error)
            }
        }

        let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
        let pngData = imageRep!.representation(using: .png, properties: [:])
        do {
            try pngData!.write(to: cacheURL)
        } catch {
            Log.shared.error(error)
        }

        return cacheURL
    }

    static func clearCache() {
        do {
            if FileManager.default.fileExists(atPath: cacheFolder.path) {
                try FileManager.default.removeItem(at: cacheFolder)
            }
        } catch {
            Log.shared.error(error)
        }
    }

    static func checkImageDimensions(_ new: NSImage, _ currentBest: NSImage?) -> Bool {
        return new.size.height > currentBest?.size.height ?? -1
    }
}
