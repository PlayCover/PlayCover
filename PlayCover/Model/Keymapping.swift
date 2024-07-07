//
//  Keymapping.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 23/08/2022.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

struct KeyModelTransform: Codable {
    var size: CGFloat
    var xCoord: CGFloat
    var yCoord: CGFloat
}

struct ButtonModel: Codable {
    var keyCode: Int
    var keyName: String
    var transform: KeyModelTransform

    init(keyCode: Int, keyName: String, transform: KeyModelTransform) {
        self.keyCode = keyCode
        self.keyName = keyName.isEmpty ? KeyCodeNames.keyCodes[keyCode] ?? "Btn" : keyName
        self.transform = transform
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(keyCode: try container.decode(Int.self, forKey: .keyCode),
                  keyName: try container.decodeIfPresent(String.self, forKey: .keyName) ?? "",
                  transform: try container.decode(KeyModelTransform.self, forKey: .transform))
    }
}

struct JoystickModel: Codable {
    var upKeyCode: Int
    var rightKeyCode: Int
    var downKeyCode: Int
    var leftKeyCode: Int
    var keyName: String
    var transform: KeyModelTransform

    init(upKeyCode: Int,
         rightKeyCode: Int,
         downKeyCode: Int,
         leftKeyCode: Int,
         keyName: String,
         transform: KeyModelTransform) {
        self.upKeyCode = upKeyCode
        self.rightKeyCode = rightKeyCode
        self.downKeyCode = downKeyCode
        self.leftKeyCode = leftKeyCode
        self.keyName = keyName
        self.transform = transform
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(upKeyCode: try container.decode(Int.self, forKey: .upKeyCode),
                  rightKeyCode: try container.decode(Int.self, forKey: .rightKeyCode),
                  downKeyCode: try container.decode(Int.self, forKey: .downKeyCode),
                  leftKeyCode: try container.decode(Int.self, forKey: .leftKeyCode),
                  keyName: try container.decodeIfPresent(String.self, forKey: .keyName) ?? "Keyboard",
                  transform: try container.decode(KeyModelTransform.self, forKey: .transform))
    }
}

struct MouseAreaModel: Codable {
    var keyName: String
    var transform: KeyModelTransform

    init(keyName: String, transform: KeyModelTransform) {
        self.keyName = keyName
        self.transform = transform
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(keyName: try container.decodeIfPresent(String.self, forKey: .keyName) ?? "Mouse",
                  transform: try container.decode(KeyModelTransform.self, forKey: .transform))
    }
}

struct Keymap: Codable {
    var buttonModels: [ButtonModel] = []
    var draggableButtonModels: [ButtonModel] = []
    var joystickModel: [JoystickModel] = []
    var mouseAreaModel: [MouseAreaModel] = []
    var bundleIdentifier: String
    var version = "2.0.0"
}

struct KeymapConfig: Codable {
    var defaultKm: String
    var aspectRatio: String
}

class Keymapping {
    static var keymappingDir: URL {
        let keymappingFolder = PlayTools.playCoverContainer.appendingPathComponent("Keymapping")
        if !FileManager.default.fileExists(atPath: keymappingFolder.path) {
            do {
                try FileManager.default.createDirectory(at: keymappingFolder,
                                                        withIntermediateDirectories: true,
                                                        attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }
        return keymappingFolder
    }

    let info: AppInfo
    let baseKeymapURL: URL
    let configURL: URL

    var keymapConfig: KeymapConfig {
        get {
            do {
                let data = try Data(contentsOf: configURL)
                let map = try PropertyListDecoder().decode(KeymapConfig.self, from: data)
                return map
            } catch {
                print(error)
                return resetConfig()
            }
        }
        set {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml

            do {
                let data = try encoder.encode(newValue)
                try data.write(to: configURL)
            } catch {
                print(error)
            }
        }
    }

    public private(set) var keymapURLs: [String: URL]

    init(_ info: AppInfo) {
        self.info = info

        baseKeymapURL = Keymapping.keymappingDir.appendingPathComponent(info.bundleIdentifier)
        self.configURL = baseKeymapURL.appendingPathComponent(".config").appendingPathExtension("plist")
        keymapURLs = [:]

        reloadKeymapCache()
    }

    public func reloadKeymapCache() {
        keymapURLs = [:]

        do {
            let directoryContents = try FileManager.default
                .contentsOfDirectory(at: baseKeymapURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])

            if directoryContents.count > 0 {
                for keymap in directoryContents where keymap.pathExtension.contains("plist") {
                    keymapURLs[keymap.deletingPathExtension().lastPathComponent] = keymap
                }

                return
            }
        } catch {
            print("failed to get keymapping directory")
            Log.shared.error(error)
        }

        setKeymap(name: "default", map: Keymap(bundleIdentifier: info.bundleIdentifier))
        reloadKeymapCache()
    }

    public func getKeymap(name: String) -> Keymap {
        if let keymapURL = keymapURLs[name] {
            do {
                let data = try Data(contentsOf: keymapURL)
                let map = try PropertyListDecoder().decode(Keymap.self, from: data)
                return map
            } catch {
                print(error)
                return reset(name: name)
            }
        } else {
            Log.shared.error("error.unknown.keymap")
            return reset(name: name)
        }
    }

    public func setKeymap(name: String, map: Keymap) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        if !keymapURLs.keys.contains(name) {
            let mapURL = baseKeymapURL.appendingPathComponent(name).appendingPathExtension("plist")

            keymapURLs[name] = mapURL
        }

        if let keymapURL = keymapURLs[name] {
            do {
                let data = try encoder.encode(map)
                try data.write(to: keymapURL)
            } catch {
                print(error)
            }
        } else {
            Log.shared.error("error.unknown.unknownError")
        }
    }

    public func renameKeymap(prevName: String, newName: String) -> Bool {
        if let keymapURL = keymapURLs[prevName] {
            do {
                let newKeymapURL = baseKeymapURL.appendingPathComponent(newName).appendingPathExtension("plist")

                try FileManager.default.moveItem(
                    at: keymapURL,
                    to: newKeymapURL
                )

                keymapURLs[newName] = newKeymapURL
                keymapURLs.removeValue(forKey: prevName)

                return true
            } catch {
                Log.shared.error(error)
                return false
            }
        } else {
            print("could not find keymap with name: \(prevName)")
            return false
        }
    }

    public func deleteKeymap(name: String) -> Bool {
        if let keymapURL = keymapURLs[name] {
            do {
                try FileManager.default.trashItem(at: keymapURL, resultingItemURL: nil)

                keymapURLs.removeValue(forKey: name)

                return true
            } catch {
                Log.shared.error(error)
                return false
            }
        } else {
            print("could not find keymap with name: \(name)")
            return false
        }
    }

    @discardableResult
    public func reset(name: String) -> Keymap {
        setKeymap(name: name, map: Keymap(bundleIdentifier: info.bundleIdentifier))
        return getKeymap(name: name)
    }

    @discardableResult
    private func resetConfig() -> KeymapConfig {
        let defaultKm = keymapURLs.keys.contains("default") ? "default" : keymapURLs.keys.first

        guard let defaultKm = defaultKm else {
            reloadKeymapCache()
            return resetConfig()
        }

        keymapConfig = KeymapConfig(defaultKm: defaultKm, aspectRatio: "auto")

        return keymapConfig
    }

    public func importKeymap(name: String, success: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = true
        openPanel.allowedContentTypes = [UTType(exportedAs: "io.playcover.PlayCover-playmap")]
        openPanel.title = NSLocalizedString("playapp.importKm", comment: "")

        openPanel.begin { result in
            if result == .OK {
                do {
                    if let selectedPath = openPanel.url {
                        let data = try Data(contentsOf: selectedPath)
                        let importedKeymap = try PropertyListDecoder().decode(Keymap.self, from: data)
                        if importedKeymap.bundleIdentifier == self.info.bundleIdentifier {
                            self.setKeymap(name: name, map: importedKeymap)
                            success(true)
                        } else {
                            if self.differentBundleIdKeymapAlert() {
                                self.setKeymap(name: name, map: importedKeymap)
                                success(true)
                            } else {
                                success(false)
                            }
                        }
                    }
                } catch {
                    if let selectedPath = openPanel.url {
                        if let keymap = LegacySettings.convertLegacyKeymapFile(selectedPath) {
                            if keymap.bundleIdentifier == self.info.bundleIdentifier {
                                self.setKeymap(name: name, map: keymap)
                                success(true)
                            } else {
                                if self.differentBundleIdKeymapAlert() {
                                    self.setKeymap(name: name, map: keymap)
                                    success(true)
                                } else {
                                    success(false)
                                }
                            }
                        } else {
                            success(false)
                        }
                    }
                }
                openPanel.close()
            }
        }
    }

    public func exportKeymap(name: String) {
        let savePanel = NSSavePanel()
        savePanel.title = NSLocalizedString("playapp.exportKm", comment: "")
        savePanel.nameFieldLabel = NSLocalizedString("playapp.exportKmPanel.fieldLabel", comment: "")
        savePanel.nameFieldStringValue = info.displayName
        savePanel.allowedContentTypes = [UTType(exportedAs: "io.playcover.PlayCover-playmap")]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false

        savePanel.begin { result in
            if result == .OK {
                do {
                    if let selectedPath = savePanel.url {
                        let encoder = PropertyListEncoder()
                        encoder.outputFormat = .xml
                        let data = try encoder.encode(self.getKeymap(name: name))
                        try data.write(to: selectedPath)
                        selectedPath.openInFinder()
                    }
                } catch {
                    savePanel.close()
                    Log.shared.error(error)
                }
                savePanel.close()
            }
        }
    }

    private func differentBundleIdKeymapAlert() -> Bool {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("alert.differentBundleIdKeymap.message", comment: "")
        alert.informativeText = NSLocalizedString("alert.differentBundleIdKeymap.text", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("button.Proceed", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))

        let result = alert.runModal()
        switch result {
        case .alertFirstButtonReturn:
            return true
        case .alertSecondButtonReturn:
            return false
        default:
            return false
        }
    }
}
