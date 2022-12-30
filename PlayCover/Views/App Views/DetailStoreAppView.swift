//
//  DetailStoreAppView.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/30/1401 AP.
//

import SwiftUI
import DataCache
import CachedAsyncImage

struct DetailStoreAppView: View {
    @State var app: StoreAppData

    @StateObject var downloadVM: DownloadVM
    @StateObject var installVM: InstallVM

    @State private var cache = DataCache.instance
    @State private var itunesResponce: ITunesResponse?
    @State private var onlineIcon: URL?
    @State private var bannerImageURLs: [URL?] = []
    @State private var localIcon: NSImage?
    @State private var truncated = true

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
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding(10)
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
                                DownloadApp(url: url, app: app,
                                            warning: nil).start()
                            }
                        }
                    } label: {
                        if downloadVM.downloading && downloadVM.storeAppData == app {
                            ZStack {
                                ProgressView("playapp.download", value: downloadVM.progress)
                                    .progressViewStyle(.circular)
                                    .font(.caption2)
                                    .textCase(.uppercase)
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
                            ZStack(alignment: .center) {
                                Capsule()
                                    .fill(.blue)
                                    .frame(width: 80, height: 25)
                                Text(downloadButtonText ?? "ipaLibrary.detailed.dlnew")
                                    .minimumScaleFactor(0.5)
                                    .font(.subheadline.bold())
                                    .textCase(.uppercase)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 25)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(installVM.installing ||
                              (downloadVM.downloading && downloadVM.storeAppData != app))
                }
                Divider()
                HStack {
                    VStack {
                        Text("ipaLibrary.detailed.appGenre")
                            .modifier(BadgeTextStyle())
                        Text(itunesResponce?.results[0].primaryGenreName
                             ?? NSLocalizedString("ipaLibrary.detailed.nil", comment: ""))
                            .font(itunesResponce == nil ? .subheadline : .title2.bold())
                            .padding(.top, 1)
                    }
                    .padding(.leading)
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.appRating")
                            .modifier(BadgeTextStyle())
                        let average = itunesResponce?.results[0].averageUserRating ?? 0
                        let rating = String(format: "%.1f", round(average * 10) / 10.0)
                        Text(itunesResponce == nil
                             ? NSLocalizedString("ipaLibrary.detailed.nil", comment: "") : rating)
                        .font(itunesResponce == nil ? .subheadline : .title2.bold())
                        .padding(.top, 1)
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.appVersion")
                            .modifier(BadgeTextStyle())
                        Text(app.version)
                            .font(.title2.bold()) .padding(.top, 1)
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.appSize")
                            .modifier(BadgeTextStyle())
                        let size = ByteCountFormatter.string(
                            fromByteCount: Int64(itunesResponce?.results[0].fileSizeBytes ?? "0") ?? 0,
                            countStyle: .file)
                        Text(itunesResponce == nil
                             ? NSLocalizedString("ipaLibrary.detailed.nil", comment: "") : size)
                        .font(itunesResponce == nil ? .subheadline : .title2.bold())
                        .padding(.top, 1)
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.appAge")
                            .modifier(BadgeTextStyle())
                        Text(itunesResponce?.results[0].trackContentRating
                             ?? NSLocalizedString("ipaLibrary.detailed.nil", comment: ""))
                            .font(itunesResponce == nil ? .subheadline : .title2.bold())
                            .padding(.top, 1)
                    }
                    .padding(.trailing)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(bannerImageURLs, id: \.self) { url in
                            CachedAsyncImage(url: url, urlCache: .screenshotCache) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(5)
                                    .shadow(radius: 5)
                                    .padding(5)
                            } placeholder: {
                                ZStack(alignment: .center) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(.regularMaterial)
                                        .shadow(radius: 5)
                                        .padding(5)
                                        .frame(width: 200, height: 170)
                                    ProgressView()
                                }
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
        if !cache.hasData(forKey: app.itunesLookup)
            && cache.readArray(forKey: app.bundleID + ".scUrls") == nil {
            await Cacher().resolveITunesData(app.itunesLookup)
        }
        itunesResponce = try? cache.readCodable(forKey: app.itunesLookup)
        if itunesResponce != nil {
            if let array = cache.readArray(forKey: app.bundleID + ".scUrls") {
                let screenshots = array.compactMap { String(describing: $0) }
                for string in screenshots {
                    bannerImageURLs.append(URL(string: string))
                }
            }
            if let url = itunesResponce?.results[0].artworkUrl512 {
                onlineIcon = URL(string: url)
            }
        } else {
            localIcon = Cacher().getLocalIcon(bundleId: app.bundleID)
        }
    }
}

struct VerticalSpacer: View {
    var body: some View {
        Spacer()
        Divider()
            .frame(height: 50)
        Spacer()
    }
}

struct BadgeTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textCase(.uppercase)
            .font(.subheadline.bold())
            .foregroundColor(Color(nsColor: .tertiaryLabelColor))
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
