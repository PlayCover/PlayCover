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

    @EnvironmentObject var downloadVM: DownloadVM

    var body: some View {
        StoreAppConditionalView(selectedBackgroundColor: $selectedBackgroundColor,
                                selectedTextColor: $selectedTextColor,
                                selected: $selected,
                                app: app,
                                isList: isList)
        /*.gesture(TapGesture(count: 2).onEnded
            if let url = URL(string: app.link) {
                downloadApp(url, app)
            }
        })
        .simultaneousGesture(TapGesture().onEnded {
            selected = app
        })*/
        .environmentObject(downloadVM)
    }

    func downloadApp(_ url: URL, _ app: StoreAppData) {
        if !downloadVM.downloading && !InstallVM.shared.installing {
            lazy var urlSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
            let downloadTask = urlSession.downloadTask(with: url, completionHandler: { url, urlResponse, error in
                observation?.invalidate()
                downloadComplete(url, urlResponse, error)
            })

            observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    downloadVM.progress = progress.fractionCompleted
                }
            }

            downloadTask.resume()
            downloadVM.downloading = true
            downloadVM.progress = 0
            downloadVM.storeAppData = app
        } else {
            Log.shared.error(PlayCoverError.waitDownload)
        }
    }

    func downloadComplete(_ url: URL?, _ urlResponce: URLResponse?, _ error: Error?) {
        if error != nil {
            Log.shared.error(error!)
        }
        if let url = url {
            do {
                var tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: URL(fileURLWithPath: "/Users"),
                                                         create: true)
                tmpDir = tmpDir
                    .appendingPathComponent(ProcessInfo().globallyUniqueString)
                try FileManager.default.createDirectory(at: tmpDir,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
                tmpDir = tmpDir
                    .appendingPathComponent(app.bundleID)
                    .appendingPathExtension("ipa")
                try FileManager.default.moveItem(at: url, to: tmpDir)
                uif.ipaUrl = tmpDir
                DispatchQueue.main.async {
                    Installer.install(ipaUrl: uif.ipaUrl!, export: false, returnCompletion: { _ in
                            AppsVM.shared.fetchApps()
                            NotifyService.shared.notify(
                                NSLocalizedString("notification.appInstalled", comment: ""),
                                NSLocalizedString("notification.appInstalled.message", comment: ""))
                    })
                }
            } catch {
                Log.shared.error(error)
            }
        }
        downloadVM.downloading = false
        downloadVM.progress = 0
        downloadVM.storeAppData = nil
    }
}

struct StoreAppConditionalView: View {
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @Binding var selected: StoreAppData?

    @State var iconURL: URL?
    @State var app: StoreAppData
    @State var isList: Bool

    @EnvironmentObject var downloadVM: DownloadVM

    var body: some View {
        Group {
            if isList {
                HStack(alignment: .center, spacing: 0) {
                    Image(systemName: "arrow.down.circle")
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
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selected?.bundleID == app.bundleID ?
                              selectedBackgroundColor : Color.clear)
                        .brightness(-0.2)
                )
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
                    Text("\(Image(systemName: "arrow.down.circle"))  \(app.name)")
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
    @State var app: StoreAppData
    @State var iconURL: URL?
    @State var bannerImageURLs: [URL?] = []
    @State var itunesResponce: ITunesResponse?
    @State var truncated = true

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

                    } label: {
                        Image(systemName: "arrow.down.circle.fill")
                            .resizable()
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 30, height: 30)
                    .padding(10)
                    Spacer()
                }
                Divider()
                if let responce = itunesResponce {
                    StatBanner(responce: responce,
                               storeData: app)
                }
                HStack {
                    Text(itunesResponce?.results[0].description ?? "")
                        .lineLimit(truncated ? 5 : nil)
                    VStack {
                        Spacer()
                        Button {
                            truncated.toggle()
                        } label: {
                            Text(truncated ? "Read more" : "Read less")
                                .foregroundColor(.accentColor)
                                .padding(.leading, 5)
                        }
                        .buttonStyle(.plain)
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

struct VerticalSpacer: View {
    var body: some View {
        Spacer()
        Divider()
            .frame(height: .infinity)
        Spacer()
    }
}

struct StatBadge: View {
    @State var header: String
    @State var stat: String

    var body: some View {
        VStack {
            Text(header)
                .textCase(.uppercase)
                .font(.subheadline.bold())
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            Spacer()
                .frame(height: 5)
            Text(stat)
                .font(.title2.bold())
        }
    }
}

struct StatBanner: View {
    @State var responce: ITunesResponse
    @State var storeData: StoreAppData

    var body: some View {
        HStack {
            Spacer()
            StatBadge(header: "Rating",
                      stat: (round(responce
                        .results[0]
                        .averageUserRating * 10) / 10.0)
                        .formatted())
            VerticalSpacer()
            StatBadge(header: "Version",
                      stat: storeData.version)
            VerticalSpacer()
            StatBadge(header: "Size",
                      stat: ByteCountFormatter
                .string(fromByteCount:
                            Int64(responce.results[0].fileSizeBytes) ?? 0,
                        countStyle: .file))
            VerticalSpacer()
            StatBadge(header: "Age",
                      stat: responce.results[0].trackContentRating)
            Spacer()
        }
        .padding()
    }
}

struct DetailStoreAppView_Preview: PreviewProvider {
    static var previews: some View {
        DetailStoreAppView(app: StoreAppData(bundleID:
                                                "com.miHoYo.GenshinImpact",
                                             name:
                                                "Genshin Impact",
                                             version:
                                                "3.2.0",
                                             itunesLookup:
                                                "http://itunes.apple.com/lookup?bundleId=com.miHoYo.GenshinImpact",
                                             link:
                                                "https://repo.amrsm.ir/ipa/Genshin-Impact_3.2.0.ipa"))
    }
}
