//
//  LegacySettings.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/09/2022.
//

// swiftlint:disable function_body_length

import Foundation

class LegacySettings {
    public static var monolithURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Preferences")
        .appendingPathComponent("playcover")
        .appendingPathExtension("plist")
    public static var doesMonolithExist: Bool {
        return FileManager.default.fileExists(atPath: monolithURL.path)
    }

    static func convertLegacyMonolithPlist(_ from: URL) {
        var dictionary: [String: Any]

        do {
            if let monolith = try [String: Any].read(from) {
                if !monolith.isEmpty {
                    dictionary = monolith

                    for (key, value) in dictionary {
                        if let dict = value as? [String: Any] {
                            if let settings = convertLegacySettingsDict(dict) {
                                let settingsURL = AppSettings.appSettingsDir.appendingPathComponent("\(key).plist")
                                do {
                                    let data = try PropertyListEncoder().encode(settings)
                                    try data.write(to: settingsURL)
                                } catch {
                                    print(error)
                                }
                            }

                            if let legacyKeymaps = dict["pc.layout"] as? [Any] {
                                let keymap = convertLegacyKeymapArray(legacyKeymaps, key)
                                let keymapURL = Keymapping.keymappingDir.appendingPathComponent("\(key).plist")
                                do {
                                    let data = try PropertyListEncoder().encode(keymap)
                                    try data.write(to: keymapURL)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Log.shared.error("Failed to read playcover.plist")
        }
    }

    static func convertLegacySettingsDict(_ from: [String: Any]) -> AppSettingsData? {
        var dictionary: [String: Any]

        if !from.isEmpty {
            dictionary = from

            var settingsData = AppSettingsData()
            settingsData.keymapping = dictionary["pc.keymapping"] as? Bool ?? true
            settingsData.mouseMapping = dictionary["pc.gamingMode"] as? Bool ?? true
            settingsData.sensitivity = dictionary["pc.sensivity"] as? Float ?? 50
            settingsData.disableTimeout = dictionary["pc.disableTimeout"] as? Bool ?? false

            return settingsData
        } else {
            return nil
        }
    }

    static func convertLegacyKeymapArray(_ from: [Any], _ bundleID: String) -> Keymap? {
        var keymap = Keymap(bundleIdentifier: bundleID)

        for item in from {
            if let data = item as? [Any] {
                if data.count == 4 {
                    let size = data[3] as? CGFloat ?? 5
                    let xCoord = data[1] as? CGFloat ?? 0
                    let yCoord = data[2] as? CGFloat ?? 0

                    let transform = KeyModelTransform(size: size,
                                                      xCoord: xCoord,
                                                      yCoord: yCoord)

                    let keyCode = data[0] as? Int ?? 0
                    keymap.buttonModels.append(ButtonModel(keyCode: keyCode,
                                                           transform: transform))
                } else if data.count == 2 {
                    let xCoord = data[0] as? CGFloat ?? 0
                    let yCoord = data[1] as? CGFloat ?? 0

                    let transform = KeyModelTransform(size: 25,
                                                      xCoord: xCoord,
                                                      yCoord: yCoord)
                    keymap.mouseAreaModel.append(MouseAreaModel(transform: transform))
                } else if data.count == 8 {
                    let size = data[6] as? CGFloat ?? 5
                    let xCoord = data[4] as? CGFloat ?? 0
                    let yCoord = data[5] as? CGFloat ?? 0

                    let transform = KeyModelTransform(size: size,
                                                      xCoord: xCoord,
                                                      yCoord: yCoord)
                    let upKeyCode = data[0] as? Int ?? 0
                    let leftKeyCode = data[2] as? Int ?? 0
                    let rightKeyCode = data[3] as? Int ?? 0
                    let downKeyCode = data[1] as? Int ?? 0
                    keymap.joystickModel.append(JoystickModel(upKeyCode: upKeyCode,
                                                              rightKeyCode: rightKeyCode,
                                                              downKeyCode: downKeyCode,
                                                              leftKeyCode: leftKeyCode,
                                                              transform: transform))
                } else if data.count == 5 {
                    let size = data[3] as? CGFloat ?? 5
                    let xCoord = data[1] as? CGFloat ?? 0
                    let yCoord = data[2] as? CGFloat ?? 0

                    let transform = KeyModelTransform(size: size,
                                                      xCoord: xCoord,
                                                      yCoord: yCoord)

                    let keyCode = data[0] as? Int ?? 0
                    keymap.draggableButtonModels.append(ButtonModel(keyCode: keyCode,
                                                           transform: transform))
                }
            }
        }

        return keymap
    }

    static func convertLegacyKeymapFile(_ from: URL) -> Keymap? {
        var dictionary: [String: Any]

        do {
            if let settings = try [String: Any].read(from) {
                if !settings.isEmpty {
                    dictionary = settings
                    if let legacyKeymaps = dictionary["pc.layout"] as? [Any] {
                        return convertLegacyKeymapArray(legacyKeymaps, from.deletingPathExtension().lastPathComponent)
                    } else {
                        Log.shared.error("Could not find keymapping in legacy file!")
                    }
                }
            }
        } catch {
            return nil
        }

        return nil
    }
}
