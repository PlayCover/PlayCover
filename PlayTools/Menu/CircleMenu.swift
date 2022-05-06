//
//  CircleMenu.swift
//  ButtonTest
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

// MARK: helpers

func customize<Type>(_ value: Type, block: (_ object: Type) -> Void) -> Type {
    block(value)
    return value
}

// MARK: Protocol

/**
 *  CircleMenuDelegate
 */
@objc public protocol CircleMenuDelegate {

    /**
     Tells the delegate the circle menu is about to draw a button for a particular index.

     - parameter circleMenu: The circle menu object informing the delegate of this impending event.
     - parameter button:     A circle menu button object that circle menu is going to use when drawing the row. Don't change button.tag
     - parameter atIndex:    An button index.
     */
    @objc optional func circleMenu(_ circleMenu: CircleMenu, willDisplay button: UIButton, atIndex: Int)

    /**
     Tells the delegate that a specified index is about to be selected.

     - parameter circleMenu: A circle menu object informing the delegate about the impending selection.
     - parameter button:     A selected circle menu button. Don't change button.tag
     - parameter atIndex:    Selected button index
     */
    @objc optional func circleMenu(_ circleMenu: CircleMenu, buttonWillSelected button: UIButton, atIndex: Int)

    /**
     Tells the delegate that the specified index is now selected.

     - parameter circleMenu: A circle menu object informing the delegate about the new index selection.
     - parameter button:     A selected circle menu button. Don't change button.tag
     - parameter atIndex:    Selected button index
     */
    @objc optional func circleMenu(_ circleMenu: CircleMenu, buttonDidSelected button: UIButton, atIndex: Int)

    /**
     Tells the delegate that the menu was collapsed - the cancel action. Fires immediately on button press

     - parameter circleMenu: A circle menu object informing the delegate about the new index selection.
     */
    @objc optional func menuCollapsed(_ circleMenu: CircleMenu)

    /**
     Tells the delegate that the menu was opened. Fires immediately on button press

     - parameter circleMenu: A circle menu object informing the delegate about the new index selection.
     */
    @objc optional func menuOpened(_ circleMenu: CircleMenu)
}

// MARK: CircleMenu

/// A Button object with pop ups buttons
open class CircleMenu: UIButton {

    // MARK: properties

    /// Buttons count
    @IBInspectable open var buttonsCount: Int = 3
    /// Circle animation duration
    @IBInspectable open var duration: Double = 2
    /// Distance between center button and buttons
    @IBInspectable open var distance: Float = 100
    /// Delay between show buttons
    @IBInspectable open var showDelay: Double = 0
    /// Start angle of the circle
    @IBInspectable open var startAngle: Float = 0
    /// End angle of the circle
    @IBInspectable open var endAngle: Float = 360

    // Pop buttons radius, if nil use center button size
    open var subButtonsRadius: CGFloat?

    // Show buttons event
    open var showButtonsEvent: UIControl.Event = UIControl.Event.touchUpInside {
        didSet {
            addActions(newEvent: showButtonsEvent, oldEvent: oldValue)
        }
    }

    /// The object that acts as the delegate of the circle menu.
    @IBOutlet open weak var delegate: AnyObject? // CircleMenuDelegate?

    var buttons: [UIButton]?
    weak var platform: UIView?

    public var customNormalIconView: UIImageView?
    public var customSelectedIconView: UIImageView?

    /**
     Initializes and returns a circle menu object.

     - parameter frame:        A rectangle specifying the initial location and size of the circle menu in its superview’s coordinates.
     - parameter normalIcon:   The image to use for the specified normal state.
     - parameter selectedIcon: The image to use for the specified selected state.
     - parameter buttonsCount: The number of buttons.
     - parameter duration:     The duration, in seconds, of the animation.
     - parameter distance:     Distance between center button and sub buttons.

     - returns: A newly created circle menu.
     */
    public init(frame: CGRect,
                normalIcon: String?,
                selectedIcon: String?,
                buttonsCount: Int = 3,
                duration: Double = 2,
                distance: Float = 100) {
        super.init(frame: frame)

        if let icon = normalIcon {
            setImage(UIImage(systemName: icon), for: .normal)
        }

        if let icon = selectedIcon {
            setImage(UIImage(systemName: icon), for: .selected)
        }

        self.buttonsCount = buttonsCount
        self.duration = duration
        self.distance = distance

        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        commonInit()
    }

    fileprivate func commonInit() {
        addActions(newEvent: showButtonsEvent)

        customNormalIconView = addCustomImageView(state: .normal)

        customSelectedIconView = addCustomImageView(state: .selected)
        customSelectedIconView?.alpha = 0

        setImage(UIImage(), for: .normal)
        setImage(UIImage(), for: .selected)
    }

    // MARK: methods

    /**
     Hide button

     - parameter duration:  The duration, in seconds, of the animation.
     - parameter hideDelay: The time to delay, in seconds.
     */
    open func hideButtons(_ duration: Double, hideDelay: Double = 0) {
        if buttons == nil {
            return
        }

        buttonsAnimationIsShow(isShow: false, duration: duration, hideDelay: hideDelay)

        tapBounceAnimation(duration: 0.5)
        tapRotatedAnimation(0.3, isSelected: false)
    }

    /**
     Check is sub buttons showed
     */
    open func buttonsIsShown() -> Bool {
        guard let buttons = self.buttons else {
            return false
        }

        for button in buttons {
            if button.alpha == 0 {
                return false
            }
        }
        return true

    }

    open override func removeFromSuperview() {
        if self.platform?.superview != nil { self.platform?.removeFromSuperview() }
        super.removeFromSuperview()
    }

    // MARK: create

    fileprivate func createButtons(platform: UIView) -> [UIButton] {
        var buttons = [UIButton]()

        let step = getArcStep()
        for index in 0 ..< buttonsCount {

            let angle: Float = startAngle + Float(index) * step
            let distance = Float(bounds.size.height / 2.0)
            let buttonSize: CGSize
            if let subButtonsRadius = self.subButtonsRadius {
                buttonSize = CGSize(width: subButtonsRadius * 2, height: subButtonsRadius * 2)
            } else {
                buttonSize = bounds.size
            }
            let button = customize(CircleMenuButton(size: buttonSize, platform: platform, distance: distance, angle: angle)) {
                $0.tag = index
                $0.addTarget(self, action: #selector(CircleMenu.buttonHandler(_:)), for: UIControl.Event.touchUpInside)
                $0.alpha = 0
            }
            buttons.append(button)
        }
        return buttons
    }

    fileprivate func addCustomImageView(state: UIControl.State) -> UIImageView? {
        guard let image = image(for: state) else {
            return nil
        }

        let iconView = customize(UIImageView(image: image)) {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.contentMode = .center
            $0.isUserInteractionEnabled = false
        }
        addSubview(iconView)

        // added constraints
        iconView.addConstraint(NSLayoutConstraint(item: iconView, attribute: .height, relatedBy: .equal, toItem: nil,
                                                  attribute: .height, multiplier: 1, constant: bounds.size.height))

        iconView.addConstraint(NSLayoutConstraint(item: iconView, attribute: .width, relatedBy: .equal, toItem: nil,
                                                  attribute: .width, multiplier: 1, constant: bounds.size.width))

        addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: iconView,
                                         attribute: .centerX, multiplier: 1, constant: 0))

        addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: iconView,
                                         attribute: .centerY, multiplier: 1, constant: 0))

        return iconView
    }

    fileprivate func createPlatform() -> UIView {
        let platform = customize(UIView(frame: .zero)) {
            $0.backgroundColor = .clear
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        superview?.insertSubview(platform, belowSubview: self)

        // constraints
        let sizeConstraints = [NSLayoutConstraint.Attribute.width, .height].map {
            NSLayoutConstraint(item: platform,
                               attribute: $0,
                               relatedBy: .equal,
                               toItem: nil,
                               attribute: $0,
                               multiplier: 1,
                               constant: CGFloat(distance * Float(2.0)))
        }
        platform.addConstraints(sizeConstraints)

        let centerConstraints = [NSLayoutConstraint.Attribute.centerX, .centerY].map {
            NSLayoutConstraint(item: self,
                               attribute: $0,
                               relatedBy: .equal,
                               toItem: platform,
                               attribute: $0,
                               multiplier: 1,
                               constant: 0)
        }
        superview?.addConstraints(centerConstraints)

        return platform
    }

    // MARK: configure

    fileprivate func addActions(newEvent: UIControl.Event, oldEvent: UIControl.Event? = nil) {
        if let oldEvent = oldEvent { removeTarget(self, action: #selector(CircleMenu.onTap), for: oldEvent) }
        addTarget(self, action: #selector(CircleMenu.onTap), for: newEvent)
    }

    /**
     Retrieves the incremental lengths between buttons. If the arc length is 360 degrees or more, the increments
     will evenly space out in a full circle. If the arc length is less than 360 degrees, the last button will be
     placed on the endAngle.
     */
    fileprivate func getArcStep() -> Float {
        var arcLength = endAngle - startAngle
        var stepCount = buttonsCount

        if arcLength < 360 {
            stepCount -= 1
        } else if arcLength > 360 {
            arcLength = 360
        }

        return arcLength / Float(stepCount)
    }

    // MARK: actions

    private var isBounceAnimating: Bool = false

    @objc func onTap() {
        guard isBounceAnimating == false else { return }
        isBounceAnimating = true

        if buttonsIsShown() == false {
            let platform = createPlatform()
            buttons = createButtons(platform: platform)
            self.platform = platform
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.delegate?.menuOpened?(self)
            }
        }
        let isShow = !buttonsIsShown()
        let duration = isShow ? 0.5 : 0.2
        buttonsAnimationIsShow(isShow: isShow, duration: duration)

        tapBounceAnimation(duration: 0.5) { [weak self] _ in self?.isBounceAnimating = false }
        tapRotatedAnimation(0.3, isSelected: isShow)
        
        if !buttonsIsShown(){
            KeymapHolder.shared.hide()
        }
    }

    @objc func buttonHandler(_ sender: CircleMenuButton) {
        guard let platform = self.platform else { return }

        delegate?.circleMenu?(self, buttonWillSelected: sender, atIndex: sender.tag)
        
        let strokeWidth: CGFloat
        if let radius = self.subButtonsRadius {
            strokeWidth = radius * 2
        } else {
            strokeWidth = bounds.size.height
        }

        let circle = CircleMenuLoader(radius: CGFloat(distance),
                                      strokeWidth: strokeWidth,
                                      platform: platform,
                                      color: sender.backgroundColor)

        if let container = sender.container { // rotation animation
            sender.rotationAnimation(container.angleZ + 360, duration: duration)
            container.superview?.bringSubviewToFront(container)
        }

        let step = getArcStep()
        circle.fillAnimation(duration, startAngle: -90 + startAngle + step * Float(sender.tag)) { [weak self] in
            self?.buttons?.forEach { $0.alpha = 0 }
        }
        circle.hideAnimation(0.5, delay: duration) { [weak self] in
            if self?.platform?.superview != nil { self?.platform?.removeFromSuperview() }
        }

        hideCenterButton(duration: 0.3)
        showCenterButton(duration: 0.525, delay: duration)

        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
            self.delegate?.circleMenu?(self, buttonDidSelected: sender, atIndex: sender.tag)
        })
}

    // MARK: animations

    fileprivate func buttonsAnimationIsShow(isShow: Bool, duration: Double, hideDelay: Double = 0) {
        guard let buttons = self.buttons else {
            return
        }

        let step = getArcStep()
        for index in 0 ..< buttonsCount {
            guard case let button as CircleMenuButton = buttons[index] else { continue }
            if isShow == true {
                delegate?.circleMenu?(self, willDisplay: button, atIndex: index)
                let angle: Float = startAngle + Float(index) * step
                button.rotatedZ(angle: angle, animated: false, delay: Double(index) * showDelay)
                button.showAnimation(distance: distance, duration: duration, delay: Double(index) * showDelay)
            } else {
                button.hideAnimation(distance: Float(bounds.size.height / 2.0), duration: duration, delay: hideDelay)
            }
        }
        if isShow == false { // hide buttons and remove
            self.buttons = nil
            delegate?.menuCollapsed?(self)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + duration) {
                if self.platform?.superview != nil { self.platform?.removeFromSuperview() }
            }
        }
    }

    fileprivate func tapBounceAnimation(duration: TimeInterval, completion: ((Bool)->())? = nil) {
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5,
                       options: UIView.AnimationOptions.curveLinear,
                       animations: { () -> Void in
                        self.transform = CGAffineTransform(scaleX: 1, y: 1)
        },
                       completion: completion)
    }

    fileprivate func tapRotatedAnimation(_ duration: Float, isSelected: Bool) {

        let addAnimations: (_ view: UIImageView, _ isShow: Bool) -> Void = { view, isShow in
            var toAngle: Float = 180.0
            var fromAngle: Float = 0
            var fromScale = 1.0
            var toScale = 0.2
            var fromOpacity = 1
            var toOpacity = 0
            if isShow == true {
                toAngle = 0
                fromAngle = -180
                fromScale = 0.2
                toScale = 1.0
                fromOpacity = 0
                toOpacity = 1
            }

            let rotation = customize(CABasicAnimation(keyPath: "transform.rotation")) {
                $0.duration = TimeInterval(duration)
                $0.toValue = (toAngle.degrees)
                $0.fromValue = (fromAngle.degrees)
                $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            }
            let fade = customize(CABasicAnimation(keyPath: "opacity")) {
                $0.duration = TimeInterval(duration)
                $0.fromValue = fromOpacity
                $0.toValue = toOpacity
                $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                $0.fillMode = CAMediaTimingFillMode.forwards
                $0.isRemovedOnCompletion = false
            }
            let scale = customize(CABasicAnimation(keyPath: "transform.scale")) {
                $0.duration = TimeInterval(duration)
                $0.toValue = toScale
                $0.fromValue = fromScale
                $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            }

            view.layer.add(rotation, forKey: nil)
            view.layer.add(fade, forKey: nil)
            view.layer.add(scale, forKey: nil)
        }

        if let customNormalIconView = self.customNormalIconView {
            addAnimations(customNormalIconView, !isSelected)
        }
        if let customSelectedIconView = self.customSelectedIconView {
            addAnimations(customSelectedIconView, isSelected)
        }

        self.isSelected = isSelected
        alpha = isSelected ? 0.3 : 1
    }

    fileprivate func hideCenterButton(duration: Double, delay: Double = 0) {
        UIView.animate(withDuration: TimeInterval(duration), delay: TimeInterval(delay),
                       options: UIView.AnimationOptions.curveEaseOut,
                       animations: { () -> Void in
                        self.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
        }, completion: nil)
    }

    fileprivate func showCenterButton(duration: Float, delay: Double) {
        UIView.animate(withDuration: TimeInterval(duration), delay: TimeInterval(delay), usingSpringWithDamping: 0.78,
                       initialSpringVelocity: 0, options: UIView.AnimationOptions.curveLinear,
                       animations: { () -> Void in
                        self.transform = CGAffineTransform(scaleX: 1, y: 1)
                        self.alpha = 1
        },
                       completion: nil)

        let rotation = customize(CASpringAnimation(keyPath: "transform.rotation")) {
            $0.duration = TimeInterval(1.5)
            $0.toValue = 0
            $0.fromValue = (Float(-180).degrees)
            $0.damping = 10
            $0.initialVelocity = 0
            $0.beginTime = CACurrentMediaTime() + delay
        }

        let fade = customize(CABasicAnimation(keyPath: "opacity")) {
            $0.duration = TimeInterval(0.01)
            $0.toValue = 0
            $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            $0.fillMode = CAMediaTimingFillMode.forwards
            $0.isRemovedOnCompletion = false
            $0.beginTime = CACurrentMediaTime() + delay
        }
        let show = customize(CABasicAnimation(keyPath: "opacity")) {
            $0.duration = TimeInterval(duration)
            $0.toValue = 1
            $0.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            $0.fillMode = CAMediaTimingFillMode.forwards
            $0.isRemovedOnCompletion = false
            $0.beginTime = CACurrentMediaTime() + delay
        }

        customNormalIconView?.layer.add(rotation, forKey: nil)
        customNormalIconView?.layer.add(show, forKey: nil)

        customSelectedIconView?.layer.add(fade, forKey: nil)
    }
}

// MARK: extension

internal extension Float {
    var radians: Float {
        return self * (Float(180) / Float.pi)
    }

    var degrees: Float {
        return self * Float.pi / 180.0
    }
}

internal extension UIView {

    var angleZ: Float {
        return atan2(Float(transform.b), Float(transform.a)).radians
    }
}
