//
//  JoystickButton.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/25.
//

import Foundation

protocol ParentElement {
    func unfocusChildren()
    var button: Element { get }
}

class ChildButtonModel: ControlModel<Button> {
    var parent: ParentElement
    init(data: Button, parent: ParentElement) {
        self.parent = parent
        super.init(data: data)
        self.setKey(code: data.keyCode)
        parent.button.addSubview(button)
    }

    override func remove() {
        parent.button.removeFromSuperview()
    }

    override func setKey(code: Int, name: String) {
        var buttonData = data
        buttonData.keyCode = code
        buttonData.keyName = name
        data = buttonData
        button.setTitle(data.keyName, for: UIControl.State.normal)
    }

    override func move(deltaY: CGFloat, deltaX: CGFloat) {
        parent.button.model?.move(deltaY: deltaY, deltaX: deltaX)
    }

    override func resize(down: Bool) {
        parent.button.model?.resize(down: down)
    }

    override func focus(_ focus: Bool) {
        if focus {
            parent.unfocusChildren()
        }
        super.focus(focus)
    }
}
