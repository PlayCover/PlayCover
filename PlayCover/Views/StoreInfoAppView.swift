//
//  StoreInfoAppView.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/24/23.
//

import SwiftUI
import DataCache
import CachedAsyncImage

struct StoreInfoAppView: View {
    @Environment(\.dismiss) var dismiss

    @EnvironmentObject var downloadVM: DownloadVM

    @ObservedObject var viewModel: StoreAppVM

    @State var closeView = false

    @State var isAvailable: Bool?
    @State var onlineIcon: URL?
    @State var localIcon: NSImage?

    @State var itunesResponse: ITunesResponse?

    @State private var cache = DataCache.instance

    var body: some View {
        VStack {
            HStack {
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
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    .frame(width: 33, height: 33)
                    if downloadVM.inProgress && downloadVM.storeAppData == viewModel.data {
                        ProgressView(value: downloadVM.progress)
                            .progressViewStyle(.circular)
                    }
                }

                VStack {
                    HStack {
                        Text(String(
                            format:
                                NSLocalizedString("ipaLibrary.info.title", comment: ""),
                            viewModel.data.name))
                        .font(.title2).bold()
                        .multilineTextAlignment(.leading)
                        Spacer()
                    }

                    let notAvailableWarning = Image(systemName: "exclamationmark.triangle")
                    let warning = NSLocalizedString("ipaLibrary.info.notAvailable", comment: "")

                    if !(isAvailable ?? true) {
                        HStack {
                            Text("\(notAvailableWarning) \(warning)")
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                }
            }

            TabView {
                StoreInfoView(data: $viewModel.data)
                    .tabItem {
                        Text("settings.tab.info")
                    }
            }
            .frame(minWidth: 500, minHeight: 250)
            HStack {
                Spacer()
                Button("button.OK") {
                    closeView.toggle()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: closeView) { _ in
            dismiss()
        }
        .task(priority: .background) {
            if let link = URL(string: viewModel.data.link) {
                _ = NetworkVM.urlAccessible(url: link, popup: false) { _, available in
                    isAvailable = available
                }
            } else {
                isAvailable = false
            }

            if !cache.hasData(forKey: viewModel.data.itunesLookup) {
                await Cacher().resolveITunesData(viewModel.data.itunesLookup)
            }
            itunesResponse = try? cache.readCodable(forKey: viewModel.data.itunesLookup)
            if let response = itunesResponse {
                onlineIcon = URL(string: response.results[0].artworkUrl512)
            } else {
                localIcon = Cacher().getLocalIcon(bundleId: viewModel.data.bundleID)
            }
        }
        .padding()
    }

}

struct StoreInfoView: View {

    @Binding var data: StoreAppData

    var body: some View {
        List {
            HStack {
                Text("settings.info.bundleName")
                Spacer()
                Text("\(data.name)")
            }
            HStack {
                Text("settings.info.bundleIdentifier")
                Spacer()
                Text("\(data.bundleID)")
            }
            HStack {
                Text("settings.info.bundleVersion")
                Spacer()
                Text("\(data.version)")
            }
            HStack {
                Text("ipaLibrary.info.itunes")
                Spacer()
                Text(.init("[\(data.itunesLookup)](\(data.itunesLookup))"))
            }
            HStack {
                Text("settings.info.url")
                Spacer()
                Text(.init("[\(data.link)](\(data.link))"))
            }
            HStack {
                Text("ipaLibrary.info.checksum")
                Spacer()
                if let checksum = data.checksum {
                    Text("\(checksum)")
                } else {
                    Text("ipaLibrary.info.checksum.none")
                }
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
        .padding()
    }

}
