//
//  EditorContainer.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/26.
//

import Foundation

class EditorViewController: UIViewController {
    override func loadView() {
        view = EditorView()
    }
}

extension UIResponder {
    public var parentViewController: UIViewController? {
        return next as? UIViewController ?? next?.parentViewController
    }
}

class EditorView: UIView {
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let btn = editor.focusedControl?.button {
            return [btn]
        }
        return [self]
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for subview in subviews {
            if let element = subview as? Element {
                element.update()
            }
        }
    }

    init() {
        super.init(frame: .zero)
        self.frame = screen.screenRect
        self.isUserInteractionEnabled = true
        let single = UITapGestureRecognizer(target: self, action: #selector(self.doubleClick(sender:)))
        single.numberOfTapsRequired = 1
        self.addGestureRecognizer(single)
    }

    @objc func doubleClick(sender: UITapGestureRecognizer) {
        for cntrl in editor.controls {
            cntrl.focus(false)
        }
        editor.focusedControl = nil
        EditorCircleMenu.shared.add(sender.location(in: self))
    }

    var label: UILabel?

    @objc func pressed(sender: UIButton!) {
        if let button = sender as? Element {
            if editor.focusedControl?.button == nil || editor.focusedControl?.button != button {
                editor.updateFocus(button: button)
            }
        }
    }

    @objc func dragged(_ sender: UIPanGestureRecognizer) {
        if let ele = sender.view as? Element {
            if editor.focusedControl?.button == nil || editor.focusedControl?.button != ele {
                editor.updateFocus(button: ele)
            }
            let translation = sender.translation(in: self)
            editor.focusedControl?.move(deltaY: translation.y,
                                        deltaX: translation.x)
            sender.setTranslation(CGPoint.zero, in: self)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
