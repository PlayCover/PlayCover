//
//  EditorElement.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/26.
//

import Foundation
class Element: UIButton {
    weak var model: ControlElement?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    func commonInit() {
        backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        addTarget(editor.view, action: #selector(editor.view.pressed(sender:)), for: .touchUpInside)
        let recognizer = UIPanGestureRecognizer(target: editor.view, action: #selector(editor.view.dragged(_:)))
        addGestureRecognizer(recognizer)
        isUserInteractionEnabled = true
        clipsToBounds = true
        titleLabel?.minimumScaleFactor = 0.01
        titleLabel?.numberOfLines = 2
        titleLabel?.adjustsFontSizeToFitWidth = true
        titleLabel?.textAlignment = .center
        configuration?.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 2, bottom: 2, trailing: 2)
        update()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    func update() {
        layer.cornerRadius = 0.5 * bounds.size.width
    }

    func setCenterXY(newX: CGFloat, newY: CGFloat) {
        self.center = CGPoint(x: newX, y: newY)
    }

    func setSize(newSize: CGFloat) {
        let center = self.center
        setWidth(width: newSize)
        setHeight(height: newSize)
        self.center = center
        update()
    }

    func focus(_ focus: Bool) {
        if focus {
            layer.borderWidth = 3
            layer.borderColor = UIColor.systemPink.cgColor
            setNeedsDisplay()
        } else {
            layer.borderWidth = 0
            setNeedsDisplay()
        }
    }
}

extension UIView {
    func setX(xCoord: CGFloat) {
        self.center = CGPoint(x: xCoord, y: self.center.y)
    }

    func setY(yCoord: CGFloat) {
        self.center = CGPoint(x: self.center.x, y: yCoord)
    }

    func setWidth(width: CGFloat) {
        var frame: CGRect = self.frame
        frame.size.width = width
        self.frame = frame
    }

    func setHeight(height: CGFloat) {
        var frame: CGRect = self.frame
        frame.size.height = height
        self.frame = frame
    }
}
