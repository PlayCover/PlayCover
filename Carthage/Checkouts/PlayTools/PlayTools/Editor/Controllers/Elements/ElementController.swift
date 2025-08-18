//
//  ElementController.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/26.
//

import Foundation

protocol ControlElement: AnyObject {
    var button: Element { get }
    func move(deltaY: CGFloat, deltaX: CGFloat)
    func focus(_ focus: Bool)
    func setKey(code: Int)
    func setKey(name: String)
    func resize(down: Bool)
    func remove()
}

class ControlModel<ElementType: BaseElement>: ControlElement {
    var data: ElementType
    var button: Element

    func focus(_ focus: Bool) {
        button.focus(focus)
//        Toast.showHint(title: "Element controller focus")
    }

    init(data: ElementType) {
        button = Element(
            // Notice: data records center coord, not start coord
            frame: CGRect(
                x: data.transform.xCoord.absoluteX - data.transform.size.absoluteSize/2,
                y: data.transform.yCoord.absoluteY - data.transform.size.absoluteSize/2,
                width: data.transform.size.absoluteSize,
                height: data.transform.size.absoluteSize
            )
        )
        self.data = data
        button.model = self
    }

    func remove() {
        self.button.removeFromSuperview()
    }

    func move(deltaY: CGFloat, deltaX: CGFloat) {
        let newX = button.center.x + deltaX
        let newY = button.center.y + deltaY
        if newX > 0 && newX < screen.width {
            data.transform.xCoord = newX.relativeX
        }
        if newY > 0 && newY < screen.height {
            data.transform.yCoord = newY.relativeY
        }
        button.setCenterXY(newX: newX, newY: newY)
    }

    func resize(down: Bool) {
        let mod = down ? 0.9 : 1/0.9
        data.transform.size = (button.frame.width * CGFloat(mod)).relativeSize
        button.setSize(newSize: data.transform.size.absoluteSize)
    }

    func setKey(code: Int, name: String) {}

    func setKey(code: Int) {
        self.setKey(code: code, name: KeyCodeNames.keyCodes[code] ?? "Btn")
    }

    func setKey(name: String) {
        self.setKey(code: KeyCodeNames.defaultCode, name: name)
    }
}
