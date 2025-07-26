//
//  KeymapViewVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 6/20/25.
//

import SwiftUI
import DataCache

class KeymapViewVM: ObservableObject {

    public let app: PlayApp
    public let cache = DataCache.instance

    @Published var selectedName: String?
    @Published var kmName = ""

    @Published var defaultKm = "default"

    @Published var showKeymapImport = false
    @Published var showKeymapRename = false
    @Published var showCreateKeymap = false

    @Published var appIcon: NSImage?

    @Published var keymapURLS: [String] = []

    init(app: PlayApp) {
        self.app = app

        self.reloadKeymapCache()
    }

    func reloadKeymapCache() {
        app.keymapping.reloadKeymapCache()

        keymapURLS = Array(app.keymapping.keymapURLs.keys).sorted(by: <)
    }

}
