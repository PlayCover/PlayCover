//
//  Joystick.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/25.
//

import Foundation

class JoystickModel: ControlModel<Joystick>, ParentElement {
    var joystickButtons = [ChildButtonModel]()

    func save() -> Joystick {
        data.upKeyCode = joystickButtons[0].data.keyCode
        data.downKeyCode = joystickButtons[1].data.keyCode
        data.leftKeyCode = joystickButtons[2].data.keyCode
        data.rightKeyCode = joystickButtons[3].data.keyCode
        return data
    }

    override init(data: Joystick) {
        super.init(data: data)
        button = JoystickElement(frame: CGRect(
            x: data.transform.xCoord.absoluteX - data.transform.size.absoluteSize/2,
            y: data.transform.yCoord.absoluteY - data.transform.size.absoluteSize/2,
            width: data.transform.size.absoluteSize,
            height: data.transform.size.absoluteSize
        ))
        button.model = self
        // joystick buttons cannot be mapped to controller keys.
        // Instead, map a real joystick to the joystick as a whole.
        var subButton = Button(
            keyCode: data.upKeyCode,
            keyName: data.keyName,
            transform: data.transform
        )
        joystickButtons.append(ChildButtonModel(
            data: subButton,
            parent: self
        ))
        subButton.keyCode = data.downKeyCode
        joystickButtons.append(ChildButtonModel(
            data: subButton,
            parent: self
        ))
        subButton.keyCode = data.leftKeyCode
        joystickButtons.append(ChildButtonModel(
            data: subButton,
            parent: self
        ))
        subButton.keyCode = data.rightKeyCode
        joystickButtons.append(ChildButtonModel(
            data: subButton,
            parent: self
        ))
        self.setKey(name: data.keyName)
        self.setJoystickMode(mode: data.mode ?? Joystick.defaultMode)
        button.update()
    }

    override func focus(_ focus: Bool) {
        super.focus(focus)
        if !focus {
            unfocusChildren()
        }
    }

    func unfocusChildren() {
        for joystickButton in joystickButtons {
            joystickButton.focus(false)
        }
    }

    override func setKey(code: Int, name: String) {
        guard let btn = button as? JoystickElement else {
            Toast.showHint(title: "Joystick setkey error", text: ["View is not JoystickView"])
            return
        }
        // `name` here may be "btn", "W", "RMB" etc.
        if name.hasSuffix("tick") {
            // Mapping a thumbstick joystick
            self.data.keyName = name
            btn.setKey(showChild: false, name: data.keyName)

        } else if name.hasSuffix("MB") {
            // Mapping a mouse joystick by pressing mouse button
            self.data.keyName = "Mouse"
            btn.setKey(showChild: false, name: data.keyName)

        } else {
            // Mapping a keyboard joystick with any other unknown name
            if JoystickModel.isAnalog(data) {
                self.data.keyName = "Keyboard"
            }
            btn.setKey(showChild: true, name: "")
        }
    }

    func setJoystickMode(mode: JoystickMode) {
        guard let btn = button as? JoystickElement else {
            Toast.showHint(title: "setJoystickMode error", text: ["View is not JoystickView"])
            return
        }
        data.mode = mode
        btn.setJoystickMode(mode: mode)
    }

    func switchToNextJoystickMode() {
        let oldMode = data.mode ?? Joystick.defaultMode
        let newMode = (oldMode == .FIXED) ? JoystickMode.FLOATING : JoystickMode.FIXED
        self.setJoystickMode(mode: newMode)
    }

    static public func isAnalog(_ data: Joystick) -> Bool {
        // possible values are
        // ["Left Thumbstick", "Right Thumbstick", "Mouse", "Keyboard", "Dynamic"]
        // Where the former three are analog
        data.keyName.contains(Character("u"))
    }
}
