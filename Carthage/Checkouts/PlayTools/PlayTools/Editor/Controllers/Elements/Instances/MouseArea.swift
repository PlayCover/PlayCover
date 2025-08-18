//
//  MouseArea.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/25.
//

import Foundation

class MouseAreaModel: ControlModel<MouseArea> {
    func save() -> MouseArea {
        data
    }

    private func setDraggableButton(code: Int) {
        EditorController.shared.removeControl()
        EditorController.shared.addDraggableButton(CGPoint(
            x: data.transform.xCoord.absoluteX,
            y: data.transform.yCoord.absoluteY
        ), code)
    }

    override func setKey(code: Int, name: String) {
        if code < 0 {
            if name.hasSuffix("tick") {
                self.data.keyName = name
            } else {
                self.data.keyName = "Mouse"
            }
        } else {
            self.setDraggableButton(code: code)
        }
        button.setTitle(data.keyName, for: UIControl.State.normal)
    }

    override init(data: MouseArea) {
        super.init(data: data)
        setKey(name: data.keyName)
    }
}
