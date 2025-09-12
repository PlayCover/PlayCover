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

enum JoystickMode: Int, Codable {
    case FIXED
    case FLOATING
}

struct JoystickModel: Codable {
    var upKeyCode: Int
    var rightKeyCode: Int
    var downKeyCode: Int
    var leftKeyCode: Int
    var keyName: String
    var transform: KeyModelTransform
    var mode: JoystickMode

    init(upKeyCode: Int,
         rightKeyCode: Int,
         downKeyCode: Int,
         leftKeyCode: Int,
         keyName: String,
         transform: KeyModelTransform,
         mode: JoystickMode) {
        self.upKeyCode = upKeyCode
        self.rightKeyCode = rightKeyCode
        self.downKeyCode = downKeyCode
        self.leftKeyCode = leftKeyCode
        self.keyName = keyName
        self.transform = transform
        self.mode = mode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(upKeyCode: try container.decode(Int.self, forKey: .upKeyCode),
                  rightKeyCode: try container.decode(Int.self, forKey: .rightKeyCode),
                  downKeyCode: try container.decode(Int.self, forKey: .downKeyCode),
                  leftKeyCode: try container.decode(Int.self, forKey: .leftKeyCode),
                  keyName: try container.decodeIfPresent(String.self, forKey: .keyName) ?? "Keyboard",
                  transform: try container.decode(KeyModelTransform.self, forKey: .transform),
                  mode: try container.decodeIfPresent(JoystickMode.self, forKey: .mode) ?? .FIXED)
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
    var defaultKm: URL
    var keymapOrder: [URL]

    init(defaultKm: URL, keymapOrder: [URL]) {
        self.defaultKm = defaultKm
        self.keymapOrder = keymapOrder
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(defaultKm: try container.decode(URL.self, forKey: .defaultKm),
                  keymapOrder: try container.decodeIfPresent([URL].self, forKey: .keymapOrder) ?? [])
    }
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

    let encoder: PropertyListEncoder

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
            do {
                let data = try encoder.encode(newValue)
                try data.write(to: configURL)
            } catch {
                print(error)
            }
        }
    }

    init(_ info: AppInfo) {
        self.info = info

        self.baseKeymapURL = Keymapping.keymappingDir.appendingPathComponent(info.bundleIdentifier)
        self.configURL = baseKeymapURL.appendingPathComponent(".config").appendingPathExtension("plist")

        self.encoder = PropertyListEncoder()
        self.encoder.outputFormat = .xml

        self.reloadKeymapCache()

    }

    private func constructKeymapPath(name: String) -> URL {
        baseKeymapURL.appendingPathComponent(name).appendingPathExtension("plist")
    }

    public func reloadKeymapCache() {
        guard FileManager.default.fileExists(atPath: baseKeymapURL.path) else {
            return
        }

        do {
            let directoryContents = try FileManager.default
                .contentsOfDirectory(at: baseKeymapURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            var keymaps: [URL] = []

            if directoryContents.count > 0 {
                for keymap in directoryContents where keymap.pathExtension.contains("plist") {
                    if !keymapConfig.keymapOrder.contains(keymap) {
                        keymapConfig.keymapOrder.append(keymap)
                    }

                    keymaps.append(keymap)
                }

                for keymap in keymapConfig.keymapOrder where !keymaps.contains(keymap) {
                    setKeymap(name: keymap.deletingPathExtension().lastPathComponent,
                              map: Keymap(bundleIdentifier: info.bundleIdentifier))
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
        do {
            let data = try Data(contentsOf: constructKeymapPath(name: name))
            let map = try PropertyListDecoder().decode(Keymap.self, from: data)
            return map
        } catch {
            print(error)
            return reset(name: name)
        }
    }

    public func createEmptyKeymap(name: String) -> Bool {
        setKeymap(name: name, map: Keymap(bundleIdentifier: info.bundleIdentifier))

        return hasKeymap(name: name)
    }

    private func setKeymap(name: String, map: Keymap) {
        let keymapPath = constructKeymapPath(name: name)

        do {
            let data = try encoder.encode(map)
            try data.write(to: keymapPath)

            if !keymapConfig.keymapOrder.contains(keymapPath) {
                keymapConfig.keymapOrder.append(keymapPath)
            }
        } catch {
            print(error)
        }
    }

    public func renameKeymap(prevName: String, newName: String) -> Bool {
        let oldPath = constructKeymapPath(name: prevName)
        let newPath = constructKeymapPath(name: newName)

        if let oldKeymapIndex = keymapConfig.keymapOrder.firstIndex(of: oldPath) {
            do {
                try FileManager.default.moveItem(at: oldPath, to: newPath)

                keymapConfig.keymapOrder[oldKeymapIndex] = newPath

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
        let keymapURL = constructKeymapPath(name: name)

        if let keymapIndex = keymapConfig.keymapOrder.firstIndex(of: keymapURL) {
            do {
                try FileManager.default.trashItem(at: keymapURL, resultingItemURL: nil)

                keymapConfig.keymapOrder.remove(at: keymapIndex)

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

    public func hasKeymap(name: String) -> Bool {
        keymapConfig.keymapOrder.contains(constructKeymapPath(name: name))
    }

    @discardableResult
    public func reset(name: String) -> Keymap {
        setKeymap(name: name, map: Keymap(bundleIdentifier: info.bundleIdentifier))
        return getKeymap(name: name)
    }

    @discardableResult
    private func resetConfig() -> KeymapConfig {
        let defaultURL = constructKeymapPath(name: "default")

        keymapConfig = KeymapConfig(defaultKm: defaultURL,
                                    keymapOrder: [defaultURL])

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
                        let data = try self.encoder.encode(self.getKeymap(name: name))
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

        return alert.runModal() == .alertFirstButtonReturn
    }
}
