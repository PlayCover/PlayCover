//
//  DetailStoreAppView.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/30/1401 AP.
//

import SwiftUI
import NavigationStack
import DataCache
import CachedAsyncImage

// swiftlint:disable type_body_length
struct DetailStoreAppView: View {
    @State var app: StoreAppData

    @StateObject var downloadVM: DownloadVM
    @StateObject var installVM: InstallVM

    @State private var cache = DataCache.instance
    @State private var itunesResponce: ITunesResponse?
    @State private var lookupIsNil = true
    @State private var onlineIcon: URL?
    @State private var localIcon: NSImage?
    @State private var appGenre = ""
    @State private var appRating = ""
    @State private var appVersion = ""
    @State private var appSize = ""
    @State private var appAge = ""
    @State private var truncated = true
    @State private var bannerImageURLs: [URL?] = []
    @State private var presentedBannerURL: URL?
    @State private var bannerIsPresented = false

    @State private var downloadButtonText: LocalizedStringKey?

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    CachedAsyncImage(url: onlineIcon, urlCache: .iconCache) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        if let image = localIcon {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Rectangle()
                                .fill(.regularMaterial)
                                .overlay {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                }
                        }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(15)
                    .shadow(radius: 2.5)
                    .padding([.top, .bottom, .trailing], 10)
                    .padding(.leading)
                    VStack(alignment: .leading) {
                        Text(app.name)
                            .font(.title.bold())
                        Text(itunesResponce?.results[0].artistName
                             ?? NSLocalizedString("ipaLibrary.detailed.nil", comment: ""))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        if let url = URL(string: app.link) {
                            if downloadVM.downloading && downloadVM.storeAppData == app {
                                DownloadApp(url: nil, app: nil, warning: nil).cancel()
                            } else {
                                DownloadApp(url: url, app: app, warning: nil).start()
                            }
                        }
                    } label: {
                        if downloadVM.downloading && downloadVM.storeAppData == app {
                            ProgressView("playapp.download", value: downloadVM.progress)
                                .progressViewStyle(.circular)
                                .font(.caption2)
                                .textCase(.uppercase)
                                .overlay {
                                    Image(systemName: "stop.fill")
                                        .foregroundColor(.blue)
                                        .padding(.bottom, 21)
                                }
                        } else if installVM.installing && downloadVM.storeAppData == app {
                            ProgressView("playapp.install", value: installVM.progress)
                                .progressViewStyle(.circular)
                                .font(.caption2)
                                .textCase(.uppercase)
                        } else {
                            Capsule()
                                .fill(.blue)
                                .frame(width: 80, height: 25)
                                .overlay {
                                    Text(downloadButtonText ?? "ipaLibrary.detailed.dlnew")
                                        .minimumScaleFactor(0.5)
                                        .font(.subheadline.bold())
                                        .textCase(.uppercase)
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 25)
                                }
                        }
                    }
                    .padding(.trailing)
                    .buttonStyle(.plain)
                    .disabled(installVM.installing ||
                              (downloadVM.downloading && downloadVM.storeAppData != app))
                }
                Divider()
                HStack {
                    Spacer()
                    Group {
                        BadgeView(lookupIsNil: $lookupIsNil,
                                  badgeInfo: $appGenre,
                                  badgeText: "ipaLibrary.detailed.appGenre",
                                  dataIsFromSource: false)
                        VerticalSpacer()
                        BadgeView(lookupIsNil: $lookupIsNil,
                                  badgeInfo: $appRating,
                                  badgeText: "ipaLibrary.detailed.appRating",
                                  dataIsFromSource: false)
                        VerticalSpacer()
                        BadgeView(lookupIsNil: $lookupIsNil,
                                  badgeInfo: $appVersion,
                                  badgeText: "ipaLibrary.detailed.appVersion",
                                  dataIsFromSource: true)
                        VerticalSpacer()
                        BadgeView(lookupIsNil: $lookupIsNil,
                                  badgeInfo: $appSize,
                                  badgeText: "ipaLibrary.detailed.appSize",
                                  dataIsFromSource: false)
                        VerticalSpacer()
                        BadgeView(lookupIsNil: $lookupIsNil,
                                  badgeInfo: $appAge,
                                  badgeText: "ipaLibrary.detailed.appAge",
                                  dataIsFromSource: false)
                    }
                    Spacer()
                }
                .padding()
                HStack {
                    Text(itunesResponce?.results[0].description
                         ?? NSLocalizedString("ipaLibrary.detailed.nodesc", comment: ""))
                    .lineLimit(truncated ? 9 : nil)
                    Spacer()
                    if itunesResponce != nil {
                        VStack {
                            Spacer()
                            Button {
                                withAnimation {
                                    truncated.toggle()
                                }
                            } label: {
                                Text(truncated ? "ipaLibrary.detailed.more" : "ipaLibrary.detailed.less")
                                    .foregroundColor(.accentColor)
                                    .padding(.leading, 5)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(bannerImageURLs, id: \.self) { url in
                            Button {
                                presentedBannerURL = url
                                bannerIsPresented = true
                            } label: {
                                CachedAsyncImage(url: url, urlCache: .screenshotCache) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                } placeholder: {
                                    Rectangle()
                                        .fill(.regularMaterial)
                                        .frame(width: 220, height: 170)
                                        .overlay {
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                        }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(7.5)
                    .shadow(radius: 2.5)
                    .cornerRadius(10)
                    .ignoresSafeArea(edges: .trailing)
                    .background(.ultraThinMaterial)
                    .frame(height: 180)
                }
                Spacer()
            }
            .padding()
            .sheet(isPresented: $bannerIsPresented) {
                EnlargedBanner(presentedBannerURL: $presentedBannerURL,
                               bannerImageURLs: $bannerImageURLs,
                               bannerIsPresented: $bannerIsPresented)
            }
        }
        .navigationTitle(app.name)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Spacer()
            }
            ToolbarItem(placement: .navigation) {
                PopView {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Rectangle())
                        .frame(width: 12.5, height: 12.5)
                }
            }
            ToolbarItem(placement: .navigation) {
                Spacer()
            }
        }
        .task(priority: .userInitiated) {
            if downloadVM.storeAppData == app {
                ToastVM.shared.isShown = false
            }
            versionCompare()
            await getData()
        }
        .onDisappear {
            ToastVM.shared.isShown = true
        }
        .onChange(of: downloadVM.storeAppData) { _ in
            if downloadVM.storeAppData == app {
                ToastVM.shared.isShown = false
            }
        }
    }

    func versionCompare() {
        if let sourceApp = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == app.bundleID }) {
            switch app.version.compare(sourceApp.info.bundleVersion, options: .numeric) {
            case .orderedAscending:
                downloadButtonText = "ipaLibrary.detailed.dlolder"
            case .orderedSame:
                downloadButtonText = "ipaLibrary.detailed.dlsame"
            case .orderedDescending:
                downloadButtonText = "ipaLibrary.detailed.dlnewer"
            }
        }
    }

    func getData() async {
        appVersion = app.version
        if !cache.hasData(forKey: app.itunesLookup)
            || cache.readArray(forKey: app.bundleID + ".scUrls") == nil {
            await Cacher().resolveITunesData(app.itunesLookup)
        }
        itunesResponce = try? cache.readCodable(forKey: app.itunesLookup)
        if itunesResponce != nil {
            lookupIsNil = false
            if let array = cache.readArray(forKey: app.bundleID + ".scUrls") {
                let screenshots = array.compactMap { String(describing: $0) }
                for string in screenshots {
                    bannerImageURLs.append(URL(string: string))
                }
            }
            if let url = itunesResponce?.results[0].artworkUrl512 {
                onlineIcon = URL(string: url)
            }
            appGenre = itunesResponce?.results[0].primaryGenreName ?? ""
            appRating = String(format: "%.1f", round(
                (itunesResponce?.results[0].averageUserRating ?? 0) * 10) / 10.0
            )
            appSize = ByteCountFormatter.string(
                fromByteCount: Int64(itunesResponce?.results[0].fileSizeBytes ?? "0") ?? 0,
                countStyle: .file
            )
            appAge = itunesResponce?.results[0].trackContentRating ?? ""
        } else {
            localIcon = Cacher().getLocalIcon(bundleId: app.bundleID)
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
