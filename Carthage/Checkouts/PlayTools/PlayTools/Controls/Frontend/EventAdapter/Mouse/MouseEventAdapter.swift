//
//  MouseEventAdapter.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation

// All mouse events under any mode

public protocol MouseEventAdapter: EventAdapter {
    func cursorHidden() -> Bool

    func handleScrollWheel(deltaX: CGFloat, deltaY: CGFloat) -> Bool
    func handleMove(deltaX: CGFloat, deltaY: CGFloat) -> Bool
    func handleLeftButton(pressed: Bool) -> Bool
    func handleOtherButton(id: Int, pressed: Bool) -> Bool
}
