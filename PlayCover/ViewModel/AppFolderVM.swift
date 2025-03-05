//
//  AppFolderVM.swift
//  PlayCover
//
//  Created by Edoardo C. on 04/03/25.
//

class AppFolderVM: ObservableObject {
    @Published var folderWrap = Folder(name: "", icon: "")
    @Published var folders: [Folder] = [] {
        didSet {
            encode()
        }
    }

    static let plistFolderApps = PlayTools.playCoverContainer
        .appendingPathComponent("appFolders")
        .appendingPathExtension("plist")

    init() {
        if !decode() {
            encode()
        }
    }

    func addFolder(folder: String, icon: String) {
        self.folders.append(Folder(name: folder, icon: icon))
    }

    @discardableResult
    func removeFolder(index: Int) -> Bool {
        let name = self.folders[index].name
        Task { @MainActor in
            let alert = NSAlert()
            alert.informativeText = String(format:
                                            NSLocalizedString("folder.remove.alert", comment: ""), name)
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("button.OK", comment: "")).hasDestructiveAction = true
            alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))
            let result = alert.runModal()
            switch result {
            case .alertFirstButtonReturn:
                self.folders.remove(at: index)
                return true
            case .alertSecondButtonReturn:
                return false
            default:
                return false
            }
        }
        return false
    }

    func encode() {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml // .xml is usually preferred for .plist

        do {
            let data = try encoder.encode(self.folders)
            try data.write(to: AppFolderVM.plistFolderApps)
            print("Folders saved to: \(AppFolderVM.plistFolderApps)")
        } catch {
            print("Error saving folders to .plist: \(error)")
        }
    }

    @discardableResult
    func decode() -> Bool {
        let decoder = PropertyListDecoder()
        do {
            let data = try Data(contentsOf: AppFolderVM.plistFolderApps)
            let decodedFolder = try decoder.decode([Folder].self, from: data)
            self._folders = Published(initialValue: decodedFolder)
            return true
        } catch {
            print("Error loading folders from .plist: \(error)")
            self._folders = Published(initialValue: [])
            return false
        }
    }

    let icons = [
        "folder",
        "keyboard",
        "graduationcap",
        "play.tv",
        "gamecontroller",
        "music.note",
        "desktopcomputer"
    ]
}
