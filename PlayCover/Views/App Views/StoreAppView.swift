//
//  StoreAppGridView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI
import DataCache
import CachedAsyncImage

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
    @EnvironmentObject var installVM: InstallVM

    var body: some View {
        StoreAppConditionalView(selectedBackgroundColor: $selectedBackgroundColor,
                                selectedTextColor: $selectedTextColor,
                                selected: $selected,
                                app: app,
                                isList: isList,
                                warningSymbol: $warningSymbol,
                                warningMessage: $warningMessage)
        .gesture(TapGesture(count: 2).onEnded {
            if let url = URL(string: app.link) {
                if downloadVM.inProgress {
                    Log.shared.error(PlayCoverError.waitDownload)
                } else {
                    DownloadApp(url: url, app: app,
                                warning: warningMessage).start()
                }
            }
        })
        .simultaneousGesture(TapGesture().onEnded {
            selected = app
        })
        .environmentObject(downloadVM)
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

    @State var app: StoreAppData
    @State var itunesResponse: ITunesResponse?
    @State var onlineIcon: URL?
    @State var localIcon: NSImage?
    @State var isList: Bool

    @Binding var warningSymbol: String?
    @Binding var warningMessage: String?

    @EnvironmentObject var downloadVM: DownloadVM

    @State private var cache = DataCache.instance

    var body: some View {
        Group {
            if isList {
                HStack(alignment: .center, spacing: 0) {
                    Image(systemName: warningSymbol ?? "arrow.down.circle")
                        .help(NSLocalizedString(warningMessage ?? "ipaLibrary.download", comment: ""))
                        .padding(.leading, 15)
                    ZStack {
                        Group {
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
                                                 .controlSize(.small)
                                         }
                                }
                            }
                        }
                        .frame(width: 30, height: 30)
                        .cornerRadius(7.5)
                        .shadow(radius: 1)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        if downloadVM.inProgress && downloadVM.storeAppData == app {
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
                        Group {
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
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(15)
                        .shadow(radius: 1)
                        if downloadVM.inProgress && downloadVM.storeAppData == app {
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
            if !cache.hasData(forKey: app.itunesLookup) {
                await Cacher().resolveITunesData(app.itunesLookup)
            }
            itunesResponse = try? cache.readCodable(forKey: app.itunesLookup)
            if let response = itunesResponse {
                onlineIcon = URL(string: response.results[0].artworkUrl512)
            } else {
                localIcon = Cacher().getLocalIcon(bundleId: app.bundleID)
            }
        }
    }
}
