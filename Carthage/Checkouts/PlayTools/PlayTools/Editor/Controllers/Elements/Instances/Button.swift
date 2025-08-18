//
//  Button.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/25.
//

import Foundation

class ButtonModel: ControlModel<Button> {

    override init(data: Button) {
        super.init(data: data)
        self.setKey(code: data.keyCode, name: data.keyName)
    }

    func save() -> Button {
        data
    }

    override func setKey(code: Int, name: String) {
        var buttonData = data
        buttonData.keyCode = code
        buttonData.keyName = name
        data = buttonData
        button.setTitle(data.keyName, for: UIControl.State.normal)
    }
}
