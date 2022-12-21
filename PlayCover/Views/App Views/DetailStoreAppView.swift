//
//  DetailStoreAppView.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/30/1401 AP.
//

import SwiftUI

struct DetailStoreAppView: View {
    @State var dlButtonText: LocalizedStringKey?
    @State var warningMessage: String?

    @State var app: StoreAppData
    @State var iconURL: URL?
    @State var bannerImageURLs: [URL?] = []
    @State var itunesResponce: ITunesResponse?
    @State var truncated = true

    @StateObject var downloadVM: DownloadVM
    @StateObject var installVM: InstallVM

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    AsyncImage(url: iconURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(10)
                    VStack {
                        HStack {
                            Text(app.name)
                                .font(.title.bold())
                            Spacer()
                        }
                        HStack {
                            Text(itunesResponce?.results[0].primaryGenreName
                                 ?? NSLocalizedString("ipaLibrary.detailed.nil", comment: "")
                            )
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    Button {
                        if let url = URL(string: app.link) {
                            let downloader = DownloadApp(url: url,
                                                         app: app,
                                                         warning: warningMessage)
                            if downloadVM.downloading && downloadVM.storeAppData == app {
                                downloader.cancel()
                            } else {
                                downloader.start()
                            }
                        }
                    } label: {
                        if downloadVM.downloading && downloadVM.storeAppData == app {
                            ZStack {
                                ProgressView("playapp.download", value: downloadVM.progress)
                                    .progressViewStyle(.circular)
                                    .font(.caption2)
                                Image(systemName: "stop.fill")
                                    .foregroundColor(.blue)
                                    .padding(.bottom, 21)
                            }
                        } else if installVM.installing && downloadVM.storeAppData == app {
                            ProgressView("playapp.install", value: installVM.progress)
                                .progressViewStyle(.circular)
                                .font(.caption2)
                        } else {
                            ZStack(alignment: .center) {
                                Capsule()
                                    .fill(.blue)
                                    .frame(width: 80, height: 25)
                                Text(dlButtonText ?? "ipaLibrary.detailed.dlnew")
                                    .minimumScaleFactor(0.5)
                                    .font(.subheadline.bold())
                                    .textCase(.uppercase)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 25)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        installVM.installing || (downloadVM.downloading && downloadVM.storeAppData != app)
                    )
                    Spacer()
                }
                Divider()
                HStack {
                    Spacer()
                    VStack {
                        Text("ipaLibrary.detailed.apprating")
                            .modifier(BadgeTextStyle())
                        let average = itunesResponce?.results[0].averageUserRating ?? 0
                        let rating = String(format: "%.1f", round(average * 10) / 10.0)
                        Text(itunesResponce == nil
                             ? NSLocalizedString("ipaLibrary.detailed.nil", comment: "")
                             : rating)
                        .font(itunesResponce == nil
                              ? .subheadline
                              : .title2.bold())
                        .padding(.top, 1)
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.appversion")
                            .modifier(BadgeTextStyle())
                        Text(app.version)
                            .font(.title2.bold())
                            .padding(.top, 1)
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.filesize")
                            .modifier(BadgeTextStyle())
                        let size = ByteCountFormatter.string(
                            fromByteCount: Int64(itunesResponce?.results[0].fileSizeBytes ?? "0") ?? 0,
                            countStyle: .file
                        )
                        Text(itunesResponce == nil
                             ? NSLocalizedString("ipaLibrary.detailed.nil", comment: "")
                             : size)
                        .font(itunesResponce == nil
                              ? .subheadline
                              : .title2.bold())
                        .padding(.top, 1)
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.apppg")
                            .modifier(BadgeTextStyle())
                        Text(itunesResponce?.results[0].trackContentRating
                             ?? NSLocalizedString("ipaLibrary.detailed.nil", comment: "")
                        )
                            .font(itunesResponce == nil
                                  ? .subheadline
                                  : .title2.bold())
                            .padding(.top, 1)
                    }
                    Spacer()
                }
                .padding()
                HStack {
                    Text(itunesResponce?.results[0].description
                         ?? NSLocalizedString("ipaLibrary.detailed.nodesc", comment: "")
                    )
                    .lineLimit(truncated ? 5 : nil)
                    Spacer()
                    if itunesResponce != nil {
                        VStack {
                            Spacer()
                            Button {
                                truncated.toggle()
                            } label: {
                                Text(truncated ? "ipaLibrary.detailed.more" : "ipaLibrary.detailed.less")
                                    .foregroundColor(.accentColor)
                                    .padding(.leading, 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(bannerImageURLs, id: \.self) { url in
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(5)
                                    .shadow(radius: 5)
                                    .padding(5)
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                    .ignoresSafeArea(edges: .trailing)
                    .background(.ultraThinMaterial)
                    .frame(height: 180)
                }
                Spacer()
            }
            .padding()
            .navigationTitle(app.name)
            .task(priority: .userInitiated) {
                if let sourceApp = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == app.bundleID }) {
                    switch app.version.compare(sourceApp.info.bundleVersion, options: .numeric) {
                    case .orderedAscending:
                        dlButtonText = "ipaLibrary.detailed.dlolder"
                        warningMessage = "ipaLibrary.version.older"
                    case .orderedSame:
                        dlButtonText = "ipaLibrary.detailed.dlsame"
                        warningMessage = "ipaLibrary.version.same"
                    case .orderedDescending:
                        dlButtonText = "ipaLibrary.detailed.dlnewer"
                        warningMessage = "ipaLibrary.version.newer"
                    default:
                        warningMessage = "ipaLibrary.download"
                    }
                }
                iconURL = await ImageCache.getOnlineImageURL(bundleID: app.bundleID,
                                                             itunesLookup: app.itunesLookup)
                itunesResponce = await ImageCache.getITunesData(app.itunesLookup)
                if itunesResponce != nil {
                    let screenshots: [String]
                    if itunesResponce!.results[0].ipadScreenshotUrls.isEmpty {
                        screenshots = itunesResponce!.results[0].screenshotUrls
                    } else {
                        screenshots = itunesResponce!.results[0].ipadScreenshotUrls
                    }
                    for string in screenshots {
                        bannerImageURLs.append(URL(string: string))
                    }
                }
            }
        }
    }
}

struct DetailStoreAppView_Preview: PreviewProvider {
    static var previews: some View {
        DetailStoreAppView(
            app: StoreAppData(
                bundleID: "com.miHoYo.GenshinImpact",
                name: "Genshin Impact", version: "3.3.0",
                itunesLookup: "http://itunes.apple.com/lookup?bundleId=com.miHoYo.GenshinImpact",
                link: "https://repo.amrsm.ir/ipa/Genshin-Impact_3.3.0.ipa"
            ),
            downloadVM: DownloadVM.shared, installVM: InstallVM.shared
        )
    }
}
