//
//  DraggableButton.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/25.
//

import Foundation

class DraggableButtonModel: ControlModel<Button>, ParentElement {
    func unfocusChildren() {
        childButton?.focus(false)
    }

    var childButton: ChildButtonModel?

    func save() -> Button {
        data.keyCode = childButton!.data.keyCode
        return data
    }

    override init(data: Button) {
        super.init(data: data)
        button = DraggableButtonElement(frame: CGRect(
            x: data.transform.xCoord.absoluteX - data.transform.size.absoluteSize/2,
            y: data.transform.yCoord.absoluteY - data.transform.size.absoluteSize/2,
            width: data.transform.size.absoluteSize,
            height: data.transform.size.absoluteSize
        ))
        button.model = self
        // temporarily, cannot map controller keys to draggable buttons
        // `data.keyName` is the key for the move area, not that of the button key.
        childButton = ChildButtonModel(
            data: self.data,
            parent: self
        )
        setKey(name: data.keyName)
        button.update()
    }

    override func setKey(code: Int, name: String) {
        if code == KeyCodeNames.defaultCode {
            // set the parent key
            self.data.keyName = name
            button.setTitle(data.keyName, for: UIControl.State.normal)
        } else {
            // set the child key
            childButton!.setKey(code: code)
        }
    }

    override func focus(_ focus: Bool) {
        super.focus(focus)
        if !focus {
            unfocusChildren()
        }
    }
}
