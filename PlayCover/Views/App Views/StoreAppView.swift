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

    var body: some View {
        StoreAppConditionalView(selectedBackgroundColor: $selectedBackgroundColor,
                                selectedTextColor: $selectedTextColor,
                                selected: $selected,
                                app: app,
                                isList: isList)
            .gesture(TapGesture(count: 2).onEnded {
                if let url = URL(string: app.link) {
                    NSWorkspace.shared.open(url)
                }
            })
            .simultaneousGesture(TapGesture().onEnded {
                selected = app
            })
    }
}

struct StoreAppConditionalView: View {
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @Binding var selected: StoreAppData?

    @State var app: StoreAppData
    @State var isList: Bool
    @State var iconUrl: URL?

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
                        .foregroundColor(selected?.id == app.id ?
                                         selectedTextColor : Color.primary)
                    Spacer()
                    Text(app.version)
                        .padding(.horizontal, 15)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selected?.id == app.id ?
                              selectedBackgroundColor : Color.clear)
                        .brightness(-0.2)
                )
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
                        Text("\(Image(systemName: "arrow.down.circle"))  \(app.name)")
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .foregroundColor(selected?.id == app.id ?
                                             selectedTextColor : Color.primary)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selected?.id == app.id ?
                                          selectedBackgroundColor : Color.clear)
                                    .brightness(-0.2)
                            )
                            .frame(width: 130, height: 20)
                    }
                }
                .frame(width: 130, height: 130)
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
