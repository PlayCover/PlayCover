//
//  LegacySettings.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/09/2022.
//

// swiftlint:disable function_body_length

import Foundation

class LegacySettings {
    static func convertLegacySettingsFile(_ from: URL) -> AppSettingsData? {
        var dictionary: [String: Any]

        do {
            if let settings = try [String: Any].read(from) {
                if !settings.isEmpty {
                    dictionary = settings

                    var settingsData = AppSettingsData()
                    settingsData.keymapping = dictionary["pc.keymapping"] as? Bool ?? true
                    settingsData.mouseMapping = dictionary["pc.gamingMode"] as? Bool ?? true
                    settingsData.sensitivity = dictionary["pc.sensivity"] as? Float ?? 50
                    settingsData.disableTimeout = dictionary["pc.disableTimeout"] as? Bool ?? false

                    return settingsData
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    static func convertLegacyKeymapFile(_ from: URL) -> Keymap? {
        var dictionary: [String: Any]

        do {
            if let settings = try [String: Any].read(from) {
                if !settings.isEmpty {
                    dictionary = settings
                    if let legacyKeymaps = dictionary["pc.layout"] as? [Any] {
                        var keymap = Keymap(bundleIdentifier: from.deletingPathExtension().lastPathComponent)

                        for item in legacyKeymaps {
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
                                    let leftKeyCode = data[1] as? Int ?? 0
                                    let rightKeyCode = data[2] as? Int ?? 0
                                    let downKeyCode = data[3] as? Int ?? 0
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
