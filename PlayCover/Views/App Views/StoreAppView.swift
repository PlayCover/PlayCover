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

    @State var isHover: Bool = false

    var body: some View {
        StoreAppConditionalView(app: app, isList: isList)
        .background(
            withAnimation {
                isHover ? Color.gray.opacity(0.3) : Color.clear
            }
                .animation(.easeInOut(duration: 0.15), value: isHover)
        )
        .cornerRadius(10)
        .onTapGesture {
            isHover = false
            if let url = URL(string: app.link) {
                NSWorkspace.shared.open(url)
            }
        }
        .onHover(perform: { hovering in
            isHover = hovering
        })
    }
}

struct StoreAppConditionalView: View {
    @State var app: StoreAppData
    @State var isList: Bool
    @State var iconUrl: URL?

    var body: some View {
        if isList {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: "arrow.down.circle")
                    .padding(.horizontal, 5)
                Spacer()
                    .frame(width: 20)
                AsyncImage(url: iconUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                .frame(width: 40, height: 40)
                .cornerRadius(10)
                .shadow(radius: 1)
                .padding(.vertical, 5)
                Spacer()
                    .frame(width: 20)
                Text(app.name)
                Spacer()
                Text(app.version)
                    .padding(.horizontal, 5)
                    .foregroundColor(.secondary)
            }
            .task {
                iconUrl = await getIconURLFromBundleIdentifier(app.id, app.region)
            }
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
                }
                .cornerRadius(15)
                .frame(width: 70, height: 70)
                .shadow(radius: 1)
                .padding(.vertical, 5)
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16))
                    Text(app.name)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 5)
            }
            .frame(width: 150, height: 150)
            .task {
                iconUrl = await getIconURLFromBundleIdentifier(app.id, app.region)
            }
        }
    }

    func getIconURLFromBundleIdentifier(_ bundleIdentifier: String,
                                        _ region: StoreAppData.Region) async -> URL? {
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
