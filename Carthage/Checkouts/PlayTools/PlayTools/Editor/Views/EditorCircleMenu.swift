//
//  DragElementsView.swift.swift
//  PlayTools
//

import Foundation
import SwiftUI

class EditorCircleMenu: CircleMenuDelegate {

    static let shared = EditorCircleMenu()

    private var menu: CircleMenu?

    public func add(_ location: CGPoint) {
        if menu != nil {
            hide()
        }
        menu = CircleMenu(
            frame: CGRect(x: 0, y: 0, width: 50, height: 50),
            normalIcon: "xmark.circle.fill",
            selectedIcon: "xmark.circle.fill",
            buttonsCount: 3,
            duration: 0.25,
            distance: 80)
        menu?.delegate = self
        menu?.center = location
        menu?.backgroundColor = UIColor.gray
        menu?.layer.cornerRadius = menu!.frame.size.width / 2
        screen.keyWindow?.addSubview(menu!)
        menu?.backgroundColor = UIColor.black
        menu?.onTap()
    }

    public func hide() {
        if self.menu != nil {
            self.menu?.removeFromSuperview()
            self.menu = nil
        }
    }

    public func hideWithAnimation() {
        if self.menu != nil {
            PlayCover.delay(0.25) {
                self.hide()
            }
        }
    }

    func circleMenu(_: CircleMenu, buttonWillSelected btn: UIButton, atIndex: Int) {
        let globalPoint = menu!.superview?.convert(menu!.center, to: nil)
        switch atIndex {
        case 0:
            EditorController.shared.addButton(globalPoint!)
        case 1:
            EditorController.shared.addJoystick(globalPoint!)
        case 2:
            EditorController.shared.addMouseArea(globalPoint!)
        default:
            Toast.showHint(title: "item \(atIndex) is not recognizable")
//            EditorController.shared.addMouseJoystick(globalPoint!)
        }
        hideWithAnimation()
    }

    func circleMenu(_: CircleMenu, willDisplay button: UIButton, atIndex: Int) {
        button.backgroundColor = UIColor.black
        button.setImage(UIImage(systemName: items[atIndex]), for: .normal)
        let highlightedImage = UIImage(named: items[atIndex])?.withRenderingMode(.alwaysTemplate)
        button.setImage(highlightedImage, for: .highlighted)
        button.tintColor = UIColor.white
    }

    private let items: [String] = [
          "circle.circle",
          "dpad",
//          "arrow.up.and.down.and.arrow.left.and.right",
//          "rb.rectangle.roundedbottom.fill",
//          "lb.rectangle.roundedbottom",
          "computermouse"
      ]
}
