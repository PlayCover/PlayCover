//
//  StoreAppGridView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct ITunesResult: Decodable {
    var isGameCenterEnabled: Bool
    var supportedDevices: [String]
    var features: [String]
    var advisories: [String]
    var screenshotUrls: [String]
    var ipadScreenshotUrls: [String]
    var appletvScreenshotUrls: [String]
    var artworkUrl60: String
    var artworkUrl512: String
    var artworkUrl100: String
    var artistViewUrl: String
    var kind: String
    var isVppDeviceBasedLicensingEnabled: Bool
    var currentVersionReleaseDate: String
    var releaseNotes: String
    var description: String
    var trackId: Int
    var trackName: String
    var bundleId: String
    var sellerName: String
    var genreIds: [String]
    var primaryGenreName: String
    var primaryGenreId: Int
    var currency: String
    var formattedPrice: String
    var contentAdvisoryRating: String
    var averageUserRatingForCurrentVersion: Float
    var userRatingCountForCurrentVersion: Int
    var trackViewUrl: String
    var trackContentRating: String
    var averageUserRating: Float
    var minimumOsVersion: String
    var trackCensoredName: String
    var languageCodesISO2A: [String]
    var fileSizeBytes: String
    var releaseDate: String
    var artistId: Int
    var artistName: String
    var genres: [String]
    var price: Float
    var version: String
    var wrapperType: String
    var userRatingCount: Int
}

struct ITunesResponse: Decodable {
    var resultCount: Int
    var results: [ITunesResult]
}

struct StoreAppView: View {
    @State var app: StoreAppData
    @State var isList: Bool

    @State var isHover: Bool = false

    var body: some View {
        StoreAppConditionalView(app: app, isList: isList)
        .background(
            withAnimation {
                isHover ? Color.gray.opacity(0.3) : Color.clear
            }
                .animation(.easeInOut(duration: 0.15), value: isHover)
        )
        .cornerRadius(10)
        .onTapGesture {
            isHover = false
            if let url = URL(string: app.link) {
                NSWorkspace.shared.open(url)
            }
        }
        .onHover(perform: { hovering in
            isHover = hovering
        })
    }
}

struct StoreAppConditionalView: View {
    @State var app: StoreAppData
    @State var isList: Bool
    @State var iconUrl: URL = URL(string: "https://google.com")!

    var body: some View {
        if isList {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: "arrow.down.circle")
                    .padding(.horizontal, 5)
                Spacer()
                    .frame(width: 20)
                AsyncImage(url: iconUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                .frame(width: 40, height: 40)
                .cornerRadius(10)
                .shadow(radius: 1)
                .padding(.vertical, 5)
                Spacer()
                    .frame(width: 20)
                Text(app.name)
                Spacer()
                Text(app.version)
                    .padding(.horizontal, 5)
                    .foregroundColor(.secondary)
            }
            .onAppear {
                getIconURLFromBundleIdentifier(app.id, app.region) { url in
                    iconUrl = url
                }
            }
        } else {
            VStack(alignment: .center, spacing: 0) {
                VStack {
                    AsyncImage(url: iconUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
                .cornerRadius(15)
                .frame(width: 70, height: 70)
                .shadow(radius: 1)
                .padding(.vertical, 5)
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16))
                    Text(app.name)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 5)
            }
            .frame(width: 150, height: 150)
            .onAppear {
                getIconURLFromBundleIdentifier(app.id, app.region) { url in
                    iconUrl = url
                }
            }
        }
    }

    public func getIconURLFromBundleIdentifier(_ bundleIdentifier: String,
                                               _ region: StoreAppData.Region,
                                               completion: @escaping (URL) -> Void) {
        let url: URL

        if region == .CN {
            url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)" + "&country=cn")!
        } else {
            url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)")!
        }

        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data else { return }

            do {
                let decoder = JSONDecoder()
                let jsonResult: ITunesResponse = try decoder.decode(ITunesResponse.self, from: data)
                if jsonResult.resultCount > 0 {
                    completion(URL(string: jsonResult.results[0].artworkUrl512)!)
                } else {
                    completion(URL(string: "https://google.com")!)
                }
            } catch {
                Log.shared.error("error: \(error)")
                completion(URL(string: "https://google.com")!)
            }
        }

        task.resume()
    }
}
