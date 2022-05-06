//
//  CircleMenuButton.swift
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

import UIKit

internal class CircleMenuButton: UIButton {

    // MARK: properties

    weak var container: UIView?

    // MARK: life cycle

    init(size: CGSize, platform: UIView, distance: Float, angle: Float = 0) {
        super.init(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))

        backgroundColor = UIColor(red: 0.79, green: 0.24, blue: 0.27, alpha: 1)
        layer.cornerRadius = size.height / 2.0

        let aContainer = createContainer(CGSize(width: size.width, height: CGFloat(distance)), platform: platform)

        // hack view for rotate
        let view = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        view.backgroundColor = UIColor.clear
        view.addSubview(self)
        // ...

        aContainer.addSubview(view)
        container = aContainer

        view.layer.transform = CATransform3DMakeRotation(-CGFloat(angle.degrees), 0, 0, 1)

        rotatedZ(angle: angle, animated: false)
    }

    internal required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: configure

    fileprivate func createContainer(_ size: CGSize, platform: UIView) -> UIView {
        let container = customize(UIView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: size))) {
            $0.backgroundColor = UIColor.clear
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.anchorPoint = CGPoint(x: 0.5, y: 1)
        }
        platform.addSubview(container)

        // added constraints
        let height = NSLayoutConstraint(item: container,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: nil,
                                        attribute: .height,
                                        multiplier: 1,
                                        constant: size.height)
        height.identifier = "height"
        container.addConstraint(height)

        container.addConstraint(NSLayoutConstraint(item: container,
                                                   attribute: .width,
                                                   relatedBy: .equal,
                                                   toItem: nil,
                                                   attribute: .width,
                                                   multiplier: 1,
                                                   constant: size.width))

        platform.addConstraint(NSLayoutConstraint(item: platform,
                                                  attribute: .centerX,
                                                  relatedBy: .equal,
                                                  toItem: container,
                                                  attribute: .centerX,
                                                  multiplier: 1,
                                                  constant: 0))

        platform.addConstraint(NSLayoutConstraint(item: platform,
                                                  attribute: .centerY,
                                                  relatedBy: .equal,
                                                  toItem: container,
                                                  attribute: .centerY,
                                                  multiplier: 1,
                                                  constant: 0))

        return container
    }

    // MARK: methods

    internal func rotatedZ(angle: Float, animated: Bool, duration: Double = 0, delay: Double = 0) {
        guard let container = self.container else {
            fatalError("contaner don't create")
        }

        let rotateTransform = CATransform3DMakeRotation(CGFloat(angle.degrees), 0, 0, 1)
        if animated {
            UIView.animate(
                withDuration: duration,
                delay: delay,
                options: UIView.AnimationOptions(),
                animations: { () -> Void in
                    container.layer.transform = rotateTransform
                },
                completion: nil)
        } else {
            container.layer.transform = rotateTransform
        }
    }
}

// MARK: Animations

internal extension CircleMenuButton {

    func showAnimation(distance: Float, duration: Double, delay: Double = 0) {
        guard let heightConstraint = (self.container?.constraints.filter { $0.identifier == "height" })?.first else {
            fatalError()
        }

        transform = CGAffineTransform(scaleX: 0, y: 0)
        container?.superview?.layoutIfNeeded()

        alpha = 0

        heightConstraint.constant = CGFloat(distance)
        UIView.animate(
            withDuration: duration,
            delay: delay,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0,
            options: UIView.AnimationOptions.curveLinear,
            animations: { () -> Void in
                self.container?.superview?.layoutIfNeeded()
                self.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                self.alpha = 1
            }, completion: { (_) -> Void in
        })
    }

    func hideAnimation(distance: Float, duration: Double, delay: Double = 0) {
        guard let heightConstraint = (self.container?.constraints.filter { $0.identifier == "height" })?.first else {
            return
        }

        heightConstraint.constant = CGFloat(distance)
        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: UIView.AnimationOptions.curveEaseIn,
            animations: { () -> Void in
                self.container?.superview?.layoutIfNeeded()
                self.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }, completion: { (_) -> Void in
                self.alpha = 0

                if let _ = self.container {
                    self.container?.removeFromSuperview() // remove container
                }
        })
    }

    func changeDistance(_ distance: CGFloat, animated _: Bool, duration: Double = 0, delay: Double = 0) {

        guard let heightConstraint = (self.container?.constraints.filter { $0.identifier == "height" })?.first else {
            fatalError()
        }

        heightConstraint.constant = distance

        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: UIView.AnimationOptions.curveEaseIn,
            animations: { () -> Void in
                self.container?.superview?.layoutIfNeeded()
            },
            completion: nil)
    }

    // MARK: layer animation

    func rotationAnimation(_ angle: Float, duration: Double) {
        let rotation = customize(CABasicAnimation(keyPath: "transform.rotation")) {
            $0.duration = TimeInterval(duration)
            $0.toValue = (angle.degrees)
            $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        }
        container?.layer.add(rotation, forKey: "rotation")
    }
}
