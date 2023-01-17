//
//  DetailStoreAppView.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/30/1401 AP.
//

import SwiftUI
import DataCache
import CachedAsyncImage

// swiftlint:disable type_body_length
struct DetailStoreAppView: View {
    @State var app: StoreAppData

    @StateObject var downloadVM: DownloadVM
    @StateObject var installVM: InstallVM

    @State private var cache = DataCache.instance
    @State private var itunesResponce: ITunesResponse?
    @State private var onlineIcon: URL?
    @State private var bannerImageURLs: [URL?] = []
    @State private var localIcon: NSImage?
    @State private var showInstallInfo = false
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
                                DownloadApp(url: url, app: app,
                                            warning: nil).start()
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
                        VStack {
                            Text("ipaLibrary.detailed.appGenre")
                                .modifier(BadgeTextStyle())
                            Text(itunesResponce?.results[0].primaryGenreName
                                 ?? NSLocalizedString("ipaLibrary.detailed.nil", comment: ""))
                            .font(itunesResponce == nil ? .subheadline : .title2.bold())
                            .padding(.top, 1)
                        }
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
                    }
                    Spacer()
                }
                .padding()
                VStack {
                     if let installInfo = app.installInfo?[0] {
                         Button {
                             withAnimation {
                                 showInstallInfo.toggle()
                             }
                         } label: {
                             HStack {
                                 Text("ipaLibrary.detailed.sourceNotes")
                                 Spacer()
                                 Image(systemName: showInstallInfo
                                       ? "chevron.up"
                                       : "chevron.down")
                             }
                             .padding(.vertical, 1)
                         }
                         .buttonStyle(.plain)
                         if showInstallInfo {
                             HStack {
                                 Spacer()
                                 Spacer()
                                 InformativeBadge(
                                     iconIsWarning: installInfo.diabledSIP,
                                     titleToShow: "ipaLibrary.detailed.sipLabelTitle",
                                     descriptionToShow: installInfo.diabledSIP
                                     ? "ipaLibrary.detailed.disabledSIPDesc"
                                     : "ipaLibrary.detailed.enabledSIPDesc"
                                 )
                                 Spacer()
                                 InformativeBadge(
                                     iconIsWarning: installInfo.noPlayTools,
                                     titleToShow: "ipaLibrary.detailed.playoolsLabelTitle",
                                     descriptionToShow: installInfo.noPlayTools
                                     ? "ipaLibrary.detailed.noPlayToolsDesc"
                                     : "ipaLibrary.detailed.withPlayToolsDesc"
                                 )
                                 Spacer()
                                 InformativeBadge(
                                     iconIsWarning: installInfo.signingSetup,
                                     titleToShow: "ipaLibrary.detailed.signinLabelTitle",
                                     descriptionToShow: installInfo.signingSetup
                                     ? "ipaLibrary.detailed.confgureSigningDesc"
                                     : "ipaLibrary.detailed.noConfgureSigningDesc"
                                 )
                                 Spacer()
                                 Spacer()
                             }
                             .padding(.vertical)
                         }
                         Divider()
                             .padding(.top, 1)
                     }
                     HStack {
                         Text(itunesResponce?.results[0].description
                              ?? NSLocalizedString("ipaLibrary.detailed.nodesc", comment: ""))
                         .lineLimit(truncated ? 7 : nil)
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
                     .padding(.top, 5)
                 }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(bannerImageURLs, id: \.self) { url in
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
                    }
                    .padding(5)
                    .shadow(radius: 2.5)
                    .cornerRadius(5)
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
            || cache.readArray(forKey: app.bundleID + ".scUrls") == nil {
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

struct InformativeBadge: View {
     @State var iconIsWarning: Bool
     @State var titleToShow: LocalizedStringKey
     @State var descriptionToShow: LocalizedStringKey
     var body: some View {
         ZStack {
             RoundedRectangle(cornerRadius: 15)
                 .fill(.ultraThickMaterial)
                 .frame(width: 175, height: 80)
                 .shadow(radius: 1)
             VStack(alignment: .center, spacing: 5.0) {
                 Image(systemName: iconIsWarning
                       ? "exclamationmark.octagon.fill"
                       : "checkmark.diamond.fill")
                 Text(titleToShow)
                     .font(.callout)
                     .multilineTextAlignment(.center)
                 Text(descriptionToShow)
                     .font(.caption2)
                     .multilineTextAlignment(.center)
             }
             .frame(width: 150)
         }
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
                link: "https://repo.amrsm.ir/ipa/Genshin-Impact_3.3.0.ipa",
                installInfo: [InstallInfo(diabledSIP: false, noPlayTools: false, signingSetup: true)]
            ),
            downloadVM: DownloadVM.shared, installVM: InstallVM.shared
        )
    }
}
