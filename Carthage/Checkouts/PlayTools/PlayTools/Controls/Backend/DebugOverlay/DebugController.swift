//
//  DebugController.swift
//  PlayTools
//
//  Created by 许沂聪 on 2024/5/28.
//

import Foundation

class DebugController {
    static let instance = DebugController()
    private init() {

    }

    private var debugView = DebugContainer.instance

    public func toggleDebugOverlay() {
        let window = screen.keyWindow
        let controller = window!.rootViewController
        let view = controller!.view
        if debugView.superview == nil {
            view!.addSubview(debugView)
            view!.bringSubviewToFront(debugView)
            debugView.isHidden = false
            debugView.isUserInteractionEnabled = false
            PlayInput.touchQueue.async {
                DebugModel.instance.enabled = true
            }
        } else {
            debugView.removeFromSuperview()
            PlayInput.touchQueue.async {
                DebugModel.instance.enabled = false
            }
        }
    }
}
