//
//  LegacySettings.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/09/2022.
//

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
                    let legacyKeymaps = dictionary["pc.layout"] as? [String: Any] ?? [:]
                    var keymap = Keymap(bundleIdentifier: "")

                    for (_, value) in legacyKeymaps {
                        if let data = value as? [String: Any] {
                            if data.count == 4 {
                                let size = Array(data)[3].value as? CGFloat ?? 5
                                let xCoord = Array(data)[1].value as? CGFloat ?? 0
                                let yCoord = Array(data)[2].value as? CGFloat ?? 0

                                let transform = KeyModelTransform(size: size,
                                                                  xCoord: xCoord,
                                                                  yCoord: yCoord)

                                let keyCode = Array(data)[0].value as? Int ?? 0
                                keymap.buttonModels.append(ButtonModel(keyCode: keyCode,
                                                                       transform: transform))
                            } else if data.count == 2 {
                                let xCoord = Array(data)[0].value as? CGFloat ?? 0
                                let yCoord = Array(data)[1].value as? CGFloat ?? 0

                                let transform = KeyModelTransform(size: 25,
                                                                  xCoord: xCoord,
                                                                  yCoord: yCoord)
                                keymap.mouseAreaModel.append(MouseAreaModel(transform: transform))
                            } else if data.count == 8 {
                                let size = Array(data)[6].value as? CGFloat ?? 5
                                let xCoord = Array(data)[4].value as? CGFloat ?? 0
                                let yCoord = Array(data)[5].value as? CGFloat ?? 0

                                let transform = KeyModelTransform(size: size,
                                                                  xCoord: xCoord,
                                                                  yCoord: yCoord)
                                let upKeyCode = Array(data)[0].value as? Int ?? 0
                                let leftKeyCode = Array(data)[1].value as? Int ?? 0
                                let rightKeyCode = Array(data)[2].value as? Int ?? 0
                                let downKeyCode = Array(data)[3].value as? Int ?? 0
                                keymap.joystickModel.append(JoystickModel(upKeyCode: upKeyCode,
                                                                          rightKeyCode: rightKeyCode,
                                                                          downKeyCode: downKeyCode,
                                                                          leftKeyCode: leftKeyCode,
                                                                          transform: transform))
                            } else if data.count == 5 {
                                let size = Array(data)[3].value as? CGFloat ?? 5
                                let xCoord = Array(data)[1].value as? CGFloat ?? 0
                                let yCoord = Array(data)[2].value as? CGFloat ?? 0

                                let transform = KeyModelTransform(size: size,
                                                                  xCoord: xCoord,
                                                                  yCoord: yCoord)

                                let keyCode = Array(data)[0].value as? Int ?? 0
                                keymap.draggableButtonModels.append(ButtonModel(keyCode: keyCode,
                                                                       transform: transform))
                            }
                        }
                    }

                    return keymap
                }
            }
        } catch {
            return nil
        }

        return nil
    }
}
