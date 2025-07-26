//
//  KeymapViewVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 6/20/25.
//

import Foundation
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

    @Published var showImportSuccess = false
    @Published var showImportFail = false

    @Published var showRenameSuccess = false
    @Published var showRenameFail = false

    @Published var showCreateKeymapSuccess = false
    @Published var showCreateKeymapFail = false

    @Published var resetKmCompletedAlert = false
    @Published var deleteKmCompletedMap = false
    @Published var deleteKmFailedMap = false

    @Published var appIcon: NSImage?

    init(app: PlayApp) {
        self.app = app
    }

}
