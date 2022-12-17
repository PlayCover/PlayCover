//
//  StoreAppGridView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//
import SwiftUI

struct StoreAppView: View {
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @Binding var selected: StoreAppData?

    @State var app: StoreAppData
    @State var isList: Bool
    @State var observation: NSKeyValueObservation?

    @State var warningSymbol: String?
    @State var warningMessage: String?

    @EnvironmentObject var downloadVM: DownloadVM

    var body: some View {
        Group {
            if #available(macOS 13.0, *) {
                StoreAppConditionalView(selectedBackgroundColor: $selectedBackgroundColor,
                                        selectedTextColor: $selectedTextColor,
                                        selected: $selected,
                                        app: app,
                                        isList: isList,
                                        warningSymbol: $warningSymbol,
                                        warningMessage: $warningMessage)
                .environmentObject(downloadVM)
            } else {
                StoreAppConditionalView(selectedBackgroundColor: $selectedBackgroundColor,
                                        selectedTextColor: $selectedTextColor,
                                        selected: $selected,
                                        app: app,
                                        isList: isList,
                                        warningSymbol: $warningSymbol,
                                        warningMessage: $warningMessage)
                .gesture(TapGesture(count: 2).onEnded {
                    if let url = URL(string: app.link) {
                        downloadApp(url, app, downloadVM, warningMessage)
                    }
                })
                .simultaneousGesture(TapGesture().onEnded {
                    selected = app
                })
                .environmentObject(downloadVM)
            }
        }
        .task(priority: .background) {
            if let sourceApp = AppsVM.shared.apps.first(where: { $0.info.bundleIdentifier == app.bundleID }) {
                switch app.version.compare(sourceApp.info.bundleVersion, options: .numeric) {
                case .orderedAscending:
                    warningSymbol = "checkmark.circle.badge.xmark"
                    warningMessage = "ipaLibrary.version.older"
                case .orderedSame:
                    warningSymbol = "checkmark.circle"
                    warningMessage = "ipaLibrary.version.same"
                case .orderedDescending:
                    warningSymbol = "checkmark.circle.trianglebadge.exclamationmark"
                    warningMessage = "ipaLibrary.version.newer"
                default:
                    warningSymbol = "arrow.down.circle"
                    warningMessage = "ipaLibrary.download"
                }
            }
        }
    }
}

struct StoreAppConditionalView: View {
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @Binding var selected: StoreAppData?

    @State var iconURL: URL?
    @State var app: StoreAppData
    @State var isList: Bool

    @Binding var warningSymbol: String?
    @Binding var warningMessage: String?

    @EnvironmentObject var downloadVM: DownloadVM

    var body: some View {
        Group {
            if isList {
                HStack(alignment: .center, spacing: 0) {
                    Image(systemName: warningSymbol ?? "arrow.down.circle")
                        .help(NSLocalizedString(warningMessage ?? "ipaLibrary.download", comment: ""))
                        .padding(.leading, 15)
                    ZStack {
                        AsyncImage(url: iconURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                                .progressViewStyle(.circular)
                        }
                            .frame(width: 30, height: 30)
                            .cornerRadius(7.5)
                            .shadow(radius: 1)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 5)
                        if downloadVM.downloading && downloadVM.storeAppData == app {
                            ProgressView(value: downloadVM.progress)
                                .progressViewStyle(.circular)
                        }
                    }
                    Text(app.name)
                        .foregroundColor(selected?.bundleID == app.bundleID ?
                                         selectedTextColor : Color.primary)
                    Spacer()
                    Text(app.version)
                        .padding(.horizontal, 15)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .background(RoundedRectangle(cornerRadius: 4)
                        .fill(selected?.bundleID == app.bundleID ?
                              selectedBackgroundColor : Color.clear)
                        .brightness(-0.2))
            } else {
                VStack {
                    ZStack {
                        AsyncImage(url: iconURL) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(15)
                            .shadow(radius: 1)
                        if downloadVM.downloading && downloadVM.storeAppData == app {
                            VStack {
                                Spacer()
                                ProgressView(value: downloadVM.progress)
                                    .padding(.horizontal, 5)
                            }
                            .frame(width: 60, height: 60)
                        }
                    }
                    Text("\(Image(systemName: warningSymbol ?? "arrow.down.circle"))  \(app.name)")
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .foregroundColor(selected?.bundleID == app.bundleID ?
                                         selectedTextColor : Color.primary)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(selected?.bundleID == app.bundleID ?
                                      selectedBackgroundColor : Color.clear)
                                .brightness(-0.2)
                        )
                        .help(NSLocalizedString(warningMessage ?? "ipaLibrary.download", comment: ""))
                        .frame(width: 130, height: 20)
                }
                .frame(width: 130, height: 130)
            }
        }
        .task(priority: .userInitiated) {
            iconURL = await ImageCache.getOnlineImageURL(bundleID: app.bundleID,
                                                         itunesLookup: app.itunesLookup)
        }
    }
}

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
                            Text(itunesResponce?.results[0].genres[0]
                                .components(separatedBy: CharacterSet.newlines).first ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    Button {
                        if let url = URL(string: app.link) {
                            downloadApp(url, app, downloadVM, warningMessage)
                        }
                    } label: {
                        if downloadVM.downloading && downloadVM.storeAppData == app {
                            ProgressView("playapp.download", value: downloadVM.progress)
                                .progressViewStyle(.circular)
                                .font(.caption2)
                        } else if installVM.installing && downloadVM.storeAppData == app {
                            ProgressView("playapp.install", value: installVM.progress)
                                .progressViewStyle(.circular)
                                .font(.caption2)
                        } else {
                            Text(dlButtonText ?? "ipaLibrary.detailed.dlnew")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                                .background(.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(downloadVM.downloading || installVM.installing)
                    Spacer()
                }
                Divider()
                HStack {
                    Spacer()
                    VStack {
                        Text("ipaLibrary.detailed.apprating")
                            .modifier(BadgeTextStyle())
                        Spacer()
                            .frame(height: 5)
                        if let average = itunesResponce?.results[0].averageUserRating ?? 0 {
                            let rating = String(format: "%.1f", round(average * 10) / 10.0)
                            Text(rating)
                                .font(.title2.bold())
                        }
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.appversion")
                            .modifier(BadgeTextStyle())
                        Spacer()
                            .frame(height: 5)
                        Text(app.version)
                            .font(.title2.bold())
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.filesize")
                            .modifier(BadgeTextStyle())
                        Spacer()
                            .frame(height: 5)
                        Text(ByteCountFormatter.string(
                            fromByteCount: Int64(itunesResponce?.results[0].fileSizeBytes ?? "0") ?? 0,
                            countStyle: .file
                        ))
                        .font(.title2.bold())
                    }
                    VerticalSpacer()
                    VStack {
                        Text("ipaLibrary.detailed.apppg")
                            .modifier(BadgeTextStyle())
                        Spacer()
                            .frame(height: 5)
                        Text(itunesResponce?.results[0].trackContentRating ?? "0")
                            .font(.title2.bold())
                    }
                    Spacer()
                }
                .padding()
                HStack {
                    Text(itunesResponce?.results[0].description ??
                         NSLocalizedString("ipaLibrary.detailed.nodesc", comment: ""))
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
