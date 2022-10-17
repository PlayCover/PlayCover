//
//  ImageCache.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 17/10/2022.
//

import Foundation

class ImageCache {
    static let cacheFolder = PlayTools.playCoverContainer.appendingPathComponent("Image Cache")

    static func getLocalImageURL(bundleID: String, bundleURL: URL, primaryIconName: String) -> URL? {
        // If cached icon for bundle id exists, skip getting it again
        if let cacheImageURL = getImageURLFromCache(bundleId: bundleID) {
            return cacheImageURL
        }

        var bestResImage: NSImage?

        do {
            let items = try FileManager.default.contentsOfDirectory(at: bundleURL, includingPropertiesForKeys: nil)

            for item in items where item.path.contains(primaryIconName) {
                do {
                    print(item.path)
                    if let image = NSImage(data: try Data(contentsOf: item)) {
                        if checkImageDimensions(image, bestResImage) {
                            bestResImage = image
                        }
                    }
                }
            }
        } catch {
            Log.shared.error(error)
        }

        if bestResImage != nil {
            print("Found icon for \(bundleID) in bundle")
            return saveImageToCache(image: bestResImage!, bundleID: bundleID)
        }

        // Failed to find icon in app bundle checking in assets
        if let assetsExtractor = try? AssetsExtractor(appUrl: bundleURL) {
            for icon in assetsExtractor.extractIcons() where checkImageDimensions(icon, bestResImage) {
                bestResImage = icon
            }
        }

        if bestResImage != nil {
            print("Found icon for \(bundleID) in assets")
            return saveImageToCache(image: bestResImage!, bundleID: bundleID)
        }

        // Failed to find any icon
        print("Failed to find icon for \(bundleID)")
        return nil
    }

    static func getOnlineImageURL(bundleID: String) -> URL? {
        if let cacheImageURL = getImageURLFromCache(bundleId: bundleID) {
            return cacheImageURL
        }

        return nil
    }

    static func getImageURLFromCache(bundleId: String) -> URL? {
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
