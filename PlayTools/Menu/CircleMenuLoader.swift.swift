//
//  CircleMenuLoader.swift
//  CircleMenu
//
// Copyright (c) 18/01/16. Ramotion Inc. (http://ramotion.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import UIKit

internal class CircleMenuLoader: UIView {

    // MARK: properties

    var circle: CAShapeLayer?

    // MARK: life cycle

    internal init(radius: CGFloat, strokeWidth: CGFloat, platform: UIView, color: UIColor?) {
        super.init(frame: CGRect(x: 0, y: 0, width: radius, height: radius))

        platform.addSubview(self)

        circle = createCircle(radius, strokeWidth: strokeWidth, color: color)
        createConstraints(platform: platform, radius: radius)

        let circleFrame = CGRect(
            x: radius * 2 - strokeWidth,
            y: radius - strokeWidth / 2,
            width: strokeWidth,
            height: strokeWidth)
        createRoundView(circleFrame, color: color)

        backgroundColor = UIColor.clear
    }

    internal required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: create

    fileprivate func createCircle(_ radius: CGFloat, strokeWidth: CGFloat, color: UIColor?) -> CAShapeLayer {

        let circlePath = UIBezierPath(
            arcCenter: CGPoint(x: radius, y: radius),
            radius: CGFloat(radius) - strokeWidth / 2.0,
            startAngle: CGFloat(0),
            endAngle: CGFloat.pi * 2,
            clockwise: true)

        let circle = customize(CAShapeLayer()) {
            $0.path = circlePath.cgPath
            $0.fillColor = UIColor.clear.cgColor
            $0.strokeColor = color?.cgColor
            $0.lineWidth = strokeWidth
        }

        layer.addSublayer(circle)
        return circle
    }

    fileprivate func createConstraints(platform: UIView, radius: CGFloat) {

        translatesAutoresizingMaskIntoConstraints = false
        // added constraints
        let sizeConstraints = [NSLayoutConstraint.Attribute.width, .height].map {
            NSLayoutConstraint(item: self,
                               attribute: $0,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: $0,
                               multiplier: 1,
                               constant: radius * 2.0)
        }
        addConstraints(sizeConstraints)

        let centerConstaraints = [NSLayoutConstraint.Attribute.centerY, .centerX].map {
            NSLayoutConstraint(item: platform,
                               attribute: $0,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: $0,
                               multiplier: 1,
                               constant: 0)
        }
        platform.addConstraints(centerConstaraints)
    }

    internal func createRoundView(_ rect: CGRect, color: UIColor?) {
        let roundView = customize(UIView(frame: rect)) {
            $0.backgroundColor = UIColor.black
            $0.layer.cornerRadius = rect.size.width / 2.0
            $0.backgroundColor = color
        }
        addSubview(roundView)
    }

    // MARK: animations

    internal func fillAnimation(_ duration: Double, startAngle: Float, completion: @escaping () -> Void) {
        guard circle != nil else {
            return
        }

        let rotateTransform = CATransform3DMakeRotation(CGFloat(startAngle.degrees), 0, 0, 1)
        layer.transform = rotateTransform

        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        let animation = customize(CABasicAnimation(keyPath: "strokeEnd")) {
            $0.duration = CFTimeInterval(duration)
            $0.fromValue = 0
            $0.toValue = 1
            $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        }
        circle?.add(animation, forKey: nil)
        CATransaction.commit()
    }

    internal func hideAnimation(_ duration: CGFloat, delay: Double, completion: @escaping () -> Void) {

        let scale = customize(CABasicAnimation(keyPath: "transform.scale")) {
            $0.toValue = 1.2
            $0.duration = CFTimeInterval(duration)
            $0.fillMode = CAMediaTimingFillMode.forwards
            $0.isRemovedOnCompletion = false
            $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            $0.beginTime = CACurrentMediaTime() + delay
        }
        layer.add(scale, forKey: nil)

        UIView.animate(
            withDuration: CFTimeInterval(duration),
            delay: delay,
            options: UIView.AnimationOptions.curveEaseIn,
            animations: { () -> Void in
                self.alpha = 0
            },
            completion: { (_) -> Void in
                self.removeFromSuperview()
                completion()
        })
    }
}
