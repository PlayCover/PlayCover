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

    @Published var selectedKeymap: URL?
    @Published var kmName = ""

    @Published var defaultKm: URL

    @Published var showKeymapImport = false
    @Published var showKeymapRename = false
    @Published var showCreateKeymap = false

    @Published var appIcon: NSImage?

    @Published var keymapURLS: [URL] = [] {
        didSet {
            app.keymapping.keymapConfig.keymapOrder = keymapURLS
        }
    }

    init(app: PlayApp) {
        self.app = app

        self.defaultKm = app.keymapping.keymapConfig.defaultKm

        self.reloadKeymapCache()
    }

    func reloadKeymapCache() {
        app.keymapping.reloadKeymapCache()

        keymapURLS = app.keymapping.keymapConfig.keymapOrder
    }

    func setDefaultKeymap(keymap: URL) {
        app.keymapping.keymapConfig.defaultKm = keymap
        defaultKm = keymap
    }

}
