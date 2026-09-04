//
//  Keymapping.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 23/08/2022.
//

import Foundation

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
