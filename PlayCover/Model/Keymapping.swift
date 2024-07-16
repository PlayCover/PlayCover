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
    let keymapURL: URL
    var keymap: Keymap {
        get {
            do {
                let data = try Data(contentsOf: keymapURL)
                let map = try PropertyListDecoder().decode(Keymap.self, from: data)
                return map
            } catch {
                print(error)
                return reset()
            }
        }
        set {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml

            do {
                let data = try encoder.encode(newValue)
                try data.write(to: keymapURL)
            } catch {
                print(error)
            }
        }
    }

    init(_ info: AppInfo) {
        self.info = info
        keymapURL = Keymapping.keymappingDir.appendingPathComponent("\(info.bundleIdentifier).plist")
    }

    @discardableResult
    public func reset() -> Keymap {
        keymap = Keymap(bundleIdentifier: info.bundleIdentifier)
        return keymap
    }

    public func importKeymap(success: @escaping (Bool) -> Void) {
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
                        if importedKeymap.bundleIdentifier == self.keymap.bundleIdentifier {
                            self.keymap = importedKeymap
                            success(true)
                        } else {
                            if self.differentBundleIdKeymapAlert() {
                                self.keymap = importedKeymap
                                success(true)
                            } else {
                                success(false)
                            }
                        }
                    }
                } catch {
                    if let selectedPath = openPanel.url {
                        if let keymap = LegacySettings.convertLegacyKeymapFile(selectedPath) {
                            if keymap.bundleIdentifier == self.keymap.bundleIdentifier {
                                self.keymap = keymap
                                success(true)
                            } else {
                                if self.differentBundleIdKeymapAlert() {
                                    self.keymap = keymap
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

    public func exportKeymap() {
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
                        let data = try encoder.encode(self.keymap)
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
