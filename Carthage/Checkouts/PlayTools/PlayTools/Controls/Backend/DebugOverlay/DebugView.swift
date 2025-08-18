//
//  DebugView.swift
//  PlayTools
//
//  Created by 许沂聪 on 2024/5/28.
//

import Foundation
import UIKit

class RingView: UIView {

    var ringColor: UIColor = .blue {
        didSet {
            shapeLayer.strokeColor = ringColor.cgColor
        }
    }

    var ringWidth: CGFloat = 10 {
        didSet {
            shapeLayer.lineWidth = ringWidth
        }
    }

    var text: String? {
        didSet {
            label.text = text
            setNeedsLayout()
        }
    }

    private let shapeLayer = CAShapeLayer()
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        shapeLayer.lineWidth = ringWidth
        shapeLayer.fillColor = nil
        shapeLayer.strokeColor = ringColor.cgColor
        layer.addSublayer(shapeLayer)

        label.textAlignment = .center
        label.textColor = .black
        addSubview(label)
    }

    public func setData(position: CGPoint, description: String, phase: UITouch.Phase) {
        center = position
        text = description
        let colorMap: [UIColor] = [.green, .red, .brown, .blue, .purple, .cyan, .gray, .darkGray, .black]
        ringColor = colorMap[phase.rawValue]
    }

    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = CGFloat(floatLiteral: 20)

        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let path = UIBezierPath(arcCenter: center, radius: radius,
                                startAngle: startAngle, endAngle: endAngle, clockwise: true)

        shapeLayer.path = path.cgPath
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Put label 30 pixels down the ring
        label.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 20)
        label.center = CGPoint(x: bounds.midX, y: bounds.midY + 30)
    }
}

class DebugContainer: UIView {
    static let instance = DebugContainer()
    private init() {
        super.init(frame: CGRect(x: 0, y: 0, width: screen.width, height: screen.height))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    // This is called once when the view shows
    override func draw(_ rect: CGRect) {
        let data = DebugModel.instance.touches
        while subviews.count < data.count {
            addSubview(RingView(frame: CGRect(x: 100, y: 100, width: 300, height: 300)))
        }
        while subviews.count > data.count {
            subviews.last?.removeFromSuperview()
        }
        var iter = data.makeIterator()
        for view in subviews {
            guard let ring = view as? RingView else {
                continue
            }
            guard let point = iter.next() else {
                continue
            }
            let description = point.description + ": " + point.phase.name()
            ring.setData(position: point.point, description: description, phase: point.phase)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if self.superview == nil {
                return
            }
            self.draw(CGRect())
        }
    }
}

extension UITouch.Phase {
    public func name() -> String {
        let nameMap = ["Began", "Moved", "Stationary", "Ended", "Cancelled",
                       "regionEntered", "regionMoved", "regionExited"]
        return nameMap[self.rawValue]
    }
}
