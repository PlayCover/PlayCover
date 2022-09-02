//
//  StoreAppGridView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct StoreAppView: View {
    @State var app: StoreAppData
    @State var isList: Bool
    @Binding var selected: StoreAppData?

    @State var isHover = false

    var body: some View {
        StoreAppConditionalView(app: app, isList: isList, selected: $selected, isHover: $isHover)
            .gesture(TapGesture(count: 2).onEnded {
                isHover = false
                if let url = URL(string: app.link) {
                    NSWorkspace.shared.open(url)
                }
            })
            .simultaneousGesture(TapGesture().onEnded {
                selected = app
            })
            .onHover(perform: { hovering in
                isHover = hovering
            })
    }
}

struct StoreAppConditionalView: View {
    @State var app: StoreAppData
    @State var isList: Bool
    @State var iconUrl: URL?
    @State var selectedBackgroundColor = Color.accentColor.opacity(0.6)
    @Binding var selected: StoreAppData?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlActiveState) var controlActiveState

    @Binding var isHover: Bool

    var body: some View {
        Group {
            if isList {
                HStack(alignment: .center, spacing: 0) {
                    Image(systemName: "arrow.down.circle")
                        .padding(.leading, 15)
                    AsyncImage(url: iconUrl) { image in
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
                    Text(app.name)
                    Spacer()
                    Text(app.version)
                        .padding(.horizontal, 15)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onChange(of: controlActiveState) { state in
                    if state == .inactive {
                        selectedBackgroundColor = .gray.opacity(0.6)
                    } else {
                        selectedBackgroundColor = .accentColor.opacity(0.6)
                    }
                }
                .background(selected?.id == app.id ?
                            selectedBackgroundColor.cornerRadius(4) : Color.clear.cornerRadius(4))
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
                        .frame(width: 60, height: 60)
                        .cornerRadius(15)
                        .shadow(radius: 1)
                        Text("\(Image(systemName: "arrow.down.circle")) \(app.name)")
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .onChange(of: controlActiveState) { state in
                                if state == .inactive {
                                    selectedBackgroundColor = .gray.opacity(0.6)
                                } else {
                                    selectedBackgroundColor = .accentColor.opacity(0.6)
                                }
                            }
                            .background(selected?.id == app.id ?
                                        selectedBackgroundColor.cornerRadius(4) : Color.clear.cornerRadius(4))
                            .frame(width: 150, height: 20)
                    }
                }
                .frame(width: 150, height: 150)
            }
        }
        .task {
            iconUrl = await getIconURLFromBundleIdentifier(app.id, app.region)
        }
    }

    func getIconURLFromBundleIdentifier(
        _ bundleIdentifier: String,
        _ region: StoreAppData.Region
    ) async -> URL? {
        let url: URL

        if region == .CN {
            url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)" + "&country=cn")!
        } else {
            url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(bundleIdentifier)")!
        }

        do {
            let (data, _) = try await URLSession.shared.data(for: URLRequest(url: url))
            let decoder = JSONDecoder()
            let jsonResult: ITunesResponse = try decoder.decode(ITunesResponse.self, from: data)
            if jsonResult.resultCount > 0 {
                return URL(string: jsonResult.results[0].artworkUrl512)!
            }
        } catch {
            Log.shared.error("error: \(error)")
        }

        return nil
    }
}
