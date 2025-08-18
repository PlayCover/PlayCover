//
//  ControllerEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation
import GameController

// All controller events under any mode

public protocol ControllerEventAdapter: EventAdapter {
    func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement)
}
