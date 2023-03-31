//
//  ITunesResponse.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 23/08/2022.
//

import Foundation

struct ITunesResult: Codable {
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

struct ITunesResponse: Codable {
    let resultCount: Int
    let results: [ITunesResult]
}

func getITunesData(_ itunesLookup: String) async -> ITunesResponse? {
    guard NetworkVM.isConnectedToNetwork(), let url = URL(string: itunesLookup) else {
        return nil
    }

    return await withCheckedContinuation { continuation in
        URLSession.shared.dataTask(with: URLRequest(url: url)) { data, _, error in
            do {
                if error == nil, let data = data {
                    let decoder = JSONDecoder()
                    let jsonResult: ITunesResponse = try decoder.decode(ITunesResponse.self, from: data)
                    continuation.resume(returning: jsonResult.resultCount > 0 ? jsonResult : nil)
                    return
                }
            } catch {
                print("Error getting iTunes data from URL: \(itunesLookup): \(error)")
            }

            continuation.resume(returning: nil)
        }.resume()
    }
}
