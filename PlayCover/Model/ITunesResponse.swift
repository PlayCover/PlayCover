//
//  ITunesResponse.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 23/08/2022.
//

import Foundation

struct ITunesResult: Codable, Sendable {
    let isGameCenterEnabled: Bool
    let features: [String]
    let advisories: [String]
    let supportedDevices: [String]
    let screenshotUrls: [String]
    let ipadScreenshotUrls: [String]
    let appletvScreenshotUrls: [String]
    let artworkUrl60: String
    let artworkUrl512: String
    let artworkUrl100: String
    let artistViewUrl: String
    let kind: String
    let artistId: Int
    let artistName: String
    let genres: [String]
    let price: Float
    let releaseNotes: String?
    let description: String
    let isVppDeviceBasedLicensingEnabled: Bool
    let primaryGenreName: String
    let primaryGenreId: Int
    let bundleId: String
    let genreIds: [String]
    let currency: String
    let releaseDate: String
    let sellerName: String
    let trackId: Int
    let trackName: String
    let currentVersionReleaseDate: String
    let averageUserRating: Float
    let averageUserRatingForCurrentVersion: Float?
    let trackViewUrl: String?
    let trackContentRating: String?
    let minimumOsVersion: String
    let trackCensoredName: String
    let languageCodesISO2A: [String]
    let fileSizeBytes: String
    let sellerUrl: String?
    let formattedPrice: String
    let contentAdvisoryRating: String
    let userRatingCountForCurrentVersion: Int
    let version: String
    let wrapperType: String
    let userRatingCount: Int
}

struct ITunesResponse: Codable, Sendable {
    let resultCount: Int
    let results: [ITunesResult]
}

private actor ITunesRequestDeduplicator {
    private var inFlight: [String: Task<ITunesResponse?, Never>] = [:]

    func value(for key: String, operation: @escaping @Sendable () async -> ITunesResponse?) async -> ITunesResponse? {
        if let task = inFlight[key] { return await task.value }
        let task = Task { await operation() }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        return result
    }
}

private let iTunesRequests = ITunesRequestDeduplicator()

func getITunesData(_ itunesLookup: String) async -> ITunesResponse? {
    if let cached: ITunesResponse = try? Cacher.shared.cache.readCodable(forKey: itunesLookup) {
        return cached
    }

    return await iTunesRequests.value(for: itunesLookup) {
        guard NetworkVM.isConnectedToNetwork(), let url = URL(string: itunesLookup) else { return nil }
        do {
            let (data, response) = try await URLSession.shared.data(for: URLRequest(url: url))
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            let value = try JSONDecoder().decode(ITunesResponse.self, from: data)
            guard value.resultCount > 0 else { return nil }
            try? Cacher.shared.cache.write(codable: value, forKey: itunesLookup)
            return value
        } catch {
            Log.shared.error(error)
            return nil
        }
    }
}
