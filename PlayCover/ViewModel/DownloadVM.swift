//
//  DownloadVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 01/10/2022.
//

import Foundation

class DownloadVM: ObservableObject {
    @Published var progress: Double = 0
    @Published var downloading = false
    @Published var storeAppData: StoreAppData?

    static let shared = DownloadVM()
}
