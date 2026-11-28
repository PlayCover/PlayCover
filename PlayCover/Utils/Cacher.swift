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

private actor IconRequestDeduplicator {
    private var inFlight: [String: Task<NSImage, Never>] = [:]

    func value(for key: String, operation: @escaping @Sendable () async -> NSImage) async -> NSImage {
        if let existing = inFlight[key] {
            return await existing.value
        }
        let task = Task { await operation() }
        inFlight[key] = task
        let image = await task.value
        inFlight[key] = nil
        return image
    }
}

class Cacher {
    static let shared = Cacher()
    @ImageCache private var imageCache
    let cache = DataCache.instance
    private let appIconCache = NSCache<NSString, NSImage>()
    private let iconRequests = IconRequestDeduplicator()
    private static let directIconQueue = DispatchQueue(
        label: "io.playcover.PlayCover.direct-icon",
        qos: .userInitiated,
        attributes: .concurrent
    )
    private static let workspaceIconQueue = DispatchQueue(
        label: "io.playcover.PlayCover.workspace-icon",
        qos: .utility
    )
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
        appIconCache.countLimit = 256
        appIconCache.totalCostLimit = 16 * 1024 * 1024
    }

    func removeImageCache() {
        imageCache.removeCache()
        appIconCache.removeAllObjects()
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

    func cachedAppIcon(forPath path: String) -> NSImage? {
        appIconCache.object(forKey: path as NSString)
    }

    func cacheAppIcon(_ icon: NSImage, forPath path: String) {
        let rep = icon.representations.first
        let pixels = max(1, (rep?.pixelsWide ?? Int(icon.size.width)) * (rep?.pixelsHigh ?? Int(icon.size.height)))
        appIconCache.setObject(icon, forKey: path as NSString, cost: max(4096, pixels * 4))
    }

    func loadAppIcon(forPath path: String) async -> NSImage {
        if let cached = cachedAppIcon(forPath: path) {
            return cached
        }
        return await iconRequests.value(for: path) { [weak self] in
            if let cached = self?.cachedAppIcon(forPath: path) {
                return cached
            }
            if let direct = await self?.loadDirectBundleIconAsync(forPath: path) {
                self?.cacheAppIcon(direct, forPath: path)
                return direct
            }
            let fallback = await Self.loadWorkspaceIconAsync(forPath: path)
            self?.cacheAppIcon(fallback, forPath: path)
            return fallback
        }
    }

    func getLocalIcon(bundleId: String) -> NSImage? {
        guard let app = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == bundleId }) else {
            return nil
        }
        let path = app.url.path
        if let cached = cachedAppIcon(forPath: path) {
            return cached
        }
        let icon = Self.readDirectBundleIcon(forPath: path) ?? NSWorkspace.shared.icon(forFile: path)
        cacheAppIcon(icon, forPath: path)
        return icon
    }

    private func loadDirectBundleIconAsync(forPath path: String) async -> NSImage? {
        await withCheckedContinuation { continuation in
            Self.directIconQueue.async {
                continuation.resume(returning: Self.readDirectBundleIcon(forPath: path))
            }
        }
    }

    private static func loadWorkspaceIconAsync(forPath path: String) async -> NSImage {
        await withCheckedContinuation { continuation in
            Self.workspaceIconQueue.async {
                continuation.resume(returning: NSWorkspace.shared.icon(forFile: path))
            }
        }
    }

    /// Reads the app's icon directly from its bundle PNG/ICNS assets without invoking
    /// `NSWorkspace.icon(forFile:)`, avoiding synchronous `lsd` bundle-registration stalls.
    private static func readDirectBundleIcon(forPath path: String) -> NSImage? {
        let bundleURL = URL(fileURLWithPath: path)
        let names = bundleIconNames(from: bundleURL.appendingPathComponent("Info.plist"))
        let iconURL = bestNamedIconURL(in: bundleURL, names: names) ?? fallbackBundleIconURL(in: bundleURL)
        guard let iconURL, let image = NSImage(contentsOf: iconURL), image.isValid else {
            return nil
        }
        return image
    }

    private static func bundleIconNames(from infoURL: URL) -> [String] {
        guard let data = try? Data(contentsOf: infoURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return []
        }
        var names: [String] = []
        for key in ["CFBundleIcons~ipad", "CFBundleIcons"] {
            if let icons = plist[key] as? [String: Any],
               let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
               let files = primary["CFBundleIconFiles"] as? [String] {
                names.append(contentsOf: files)
            }
        }
        if let files = plist["CFBundleIconFiles"] as? [String] {
            names.append(contentsOf: files)
        }
        if let single = plist["CFBundleIconFile"] as? String, !single.isEmpty {
            names.append(single)
        }
        return names
    }

    private static func bestNamedIconURL(in bundleURL: URL, names: [String]) -> URL? {
        let suffixes = [
            "76x76@2x~ipad.png", "60x60@3x.png", "60x60@2x.png",
            "@3x~ipad.png", "@2x~ipad.png", "@3x.png", "@2x.png",
            ".png", ".icns", ""
        ]
        let fileManager = FileManager.default
        var bestURL: URL?
        var bestSize = -1
        for rawName in names {
            let trimmed = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            for suffix in suffixes {
                let candidateName = trimmed.hasSuffix(".png") || trimmed.hasSuffix(".icns")
                    ? trimmed : trimmed + suffix
                let candidateURL = bundleURL.appendingPathComponent(candidateName)
                guard fileManager.fileExists(atPath: candidateURL.path) else { continue }
                let size = (try? candidateURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if size > bestSize {
                    bestSize = size
                    bestURL = candidateURL
                }
            }
        }
        return bestURL
    }

    private static func fallbackBundleIconURL(in bundleURL: URL) -> URL? {
        guard let items = try? FileManager.default.contentsOfDirectory(
            at: bundleURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }
        var bestURL: URL?
        var bestSize = -1
        for item in items {
            let lower = item.lastPathComponent.lowercased()
            let isIcon = (lower.hasPrefix("appicon") || lower.hasPrefix("icon")) && lower.hasSuffix(".png")
            guard isIcon || lower.hasSuffix(".icns") else { continue }
            let size = (try? item.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            if size > bestSize {
                bestSize = size
                bestURL = item
            }
        }
        return bestURL
    }
}

extension URLCache {
    static let iconCache = URLCache(memoryCapacity: 4*1024*1024, diskCapacity: 20*1024*1024) // 4MB and 20MB
}
