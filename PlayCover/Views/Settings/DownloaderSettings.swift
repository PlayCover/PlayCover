//
//  DownloaderSettings.swift
//  PlayCover
//
//  Created by 이승윤 on 2023/01/31.
//

import SwiftUI

class DownloaderPreferences: NSObject, ObservableObject {
    static var shared = DownloaderPreferences()

    @AppStorage("DownloaderChunkSize") var chunkSize = 1024 * 1024 // 1MB

    @AppStorage("DownloaderMaxConnections") var maxConnections = 6
}

struct DownloaderSettings: View {
    public static var shared = DownloaderPreferences()

    @ObservedObject var downloaderPreferences = DownloaderPreferences.shared

    var body: some View {
        Form {
            TextField("Chunk Size", value: downloaderPreferences.$chunkSize, formatter: NumberFormatter())
            TextField("Max Connections", value: downloaderPreferences.$maxConnections, formatter: NumberFormatter())
            Spacer()
        }
        .padding(20)
        .frame(width: 350, height: 100, alignment: .center)
    }
}
