//
//  PlayAction.swift
//  PlayTools
//

// swiftlint:disable file_length
import Foundation

protocol Action {
    func invalidate()
}
// Actions hold touch point IDs, perform fake touch

class ButtonAction: Action {
    func invalidate() {
        Toucher.touchcam(point: point, phase: UITouch.Phase.ended, tid: &id,
                         actionName: "Button", keyName: keyName)
    }

    let keyCode: Int
    let keyName: String
    let point: CGPoint
    var id: Int?

    init(keyCode: Int, keyName: String, point: CGPoint) {
        self.keyCode = keyCode
        self.keyName = keyName
        self.point = point
        let code = keyCode
        let codeName = KeyCodeNames.keyCodes[code] ?? "Btn"
        // TODO: set both key names in draggable button, so as to depracate key code
        ActionDispatcher.register(key: code == KeyCodeNames.defaultCode ? keyName: codeName, handler: self.update)
    }

    convenience init(data: Button) {
        let keyCode = data.keyCode
        self.init(
            keyCode: keyCode,
            keyName: data.keyName,
            point: CGPoint(
                x: data.transform.xCoord.absoluteX,
                y: data.transform.yCoord.absoluteY))
    }

    func update(pressed: Bool) {
        if pressed {
            Toucher.touchcam(point: point, phase: UITouch.Phase.began, tid: &id,
                             actionName: "Button", keyName: keyName)
        } else {
            Toucher.touchcam(point: point, phase: UITouch.Phase.ended, tid: &id,
                             actionName: "Button", keyName: keyName)
        }
    }
}

class DraggableButtonAction: ButtonAction {
    var releasePoint: CGPoint

    override init(keyCode: Int, keyName: String, point: CGPoint) {
        self.releasePoint = point
        super.init(keyCode: keyCode, keyName: keyName, point: point)
    }

    override func update(pressed: Bool) {
        if pressed {
            Toucher.touchcam(point: point, phase: UITouch.Phase.began, tid: &id,
                             actionName: "DraggableButton", keyName: keyName)
            self.releasePoint = point
            ActionDispatcher.register(key: KeyCodeNames.mouseMove,
                                      handler: self.onMouseMoved,
                                      priority: .DRAGGABLE)
            if !mode.cursorHidden() {
                AKInterface.shared!.hideCursor()
            }
        } else {
            Toucher.touchcam(point: releasePoint, phase: UITouch.Phase.ended, tid: &id,
                             actionName: "DraggableButton", keyName: keyName)
            if id == nil {
                ActionDispatcher.unregister(key: KeyCodeNames.mouseMove)
                if !mode.cursorHidden() {
                    AKInterface.shared!.unhideCursor()
                }
            }
        }
    }

    override func invalidate() {
        ActionDispatcher.unregister(key: KeyCodeNames.mouseMove)
        super.invalidate()
    }

    func onMouseMoved(deltaX: CGFloat, deltaY: CGFloat) {
        self.releasePoint.x += deltaX
        self.releasePoint.y -= deltaY
        Toucher.touchcam(point: self.releasePoint, phase: UITouch.Phase.moved, tid: &id,
                         actionName: "DraggableButton", keyName: keyName)
    }
}

class ContinuousJoystickAction: Action {
    var key: String
    var center: CGPoint
    var position: CGPoint!
    private var id: Int?
    var sensitivity: CGFloat
    var mode: JoystickMode
    var begun = false

    init(data: Joystick) {
        self.center = CGPoint(
            x: data.transform.xCoord.absoluteX,
            y: data.transform.yCoord.absoluteY)
        self.key = data.keyName
        position = center
        self.sensitivity = data.transform.size.absoluteSize / 4
        self.mode = data.mode ?? Joystick.defaultMode
        if key == KeyCodeNames.mouseMove {
            ActionDispatcher.register(key: key, handler: self.mouseUpdate)
        } else {
            ActionDispatcher.register(key: key, handler: self.thumbstickUpdate)
        }
    }

    func update(_ point: CGPoint) {
        let dis = (center.x - point.x).magnitude + (center.y - point.y).magnitude
        if dis < 16 {
            if begun {
                begun = false
                Toucher.touchcam(point: point, phase: UITouch.Phase.ended, tid: &id,
                                 actionName: "ControllerJoystick", keyName: key)
            }
        } else if !begun {
            begun = true
            beginTouch(point)
        } else {
            Toucher.touchcam(point: point, phase: UITouch.Phase.moved, tid: &id,
                             actionName: "ControllerJoystick", keyName: key)
        }
    }

    func beginTouch(_ point: CGPoint) {
        if mode == .FIXED {
            Toucher.touchcam(point: point, phase: UITouch.Phase.began, tid: &id,
                             actionName: "ControllerJoystick", keyName: key)
        } else if mode == .FLOATING {
            Toucher.touchcam(point: self.center, phase: UITouch.Phase.began, tid: &id,
                             actionName: "ControllerJoystick", keyName: key)
            PlayInput.touchQueue.asyncAfter(deadline: .now() + 0.04, qos: .userInitiated) {
                if self.id == nil {
                    return
                }
                Toucher.touchcam(point: point, phase: UITouch.Phase.moved, tid: &self.id,
                                 actionName: "ControllerJoystick", keyName: self.key)
            }
        }
    }

    func thumbstickUpdate(_ deltaX: CGFloat, _ deltaY: CGFloat) {
        let pos = CGPoint(x: center.x + deltaX * sensitivity,
                          y: center.y - deltaY * sensitivity)
        self.update(pos)
    }

    func mouseUpdate(_ deltaX: CGFloat, _ deltaY: CGFloat) {
        position.x += deltaX
        position.y -= deltaY
        self.update(position)
    }

    func invalidate() {
        Toucher.touchcam(point: CGPoint(x: 10, y: 10), phase: UITouch.Phase.ended, tid: &id,
                         actionName: "ControllerJoystick", keyName: key)
    }
}

class JoystickAction: Action {
    let keys: [Int]
    let center: CGPoint
    var touch: CGPoint
    let shift: CGFloat
    var mode: JoystickMode
    var id: Int?
    private var keyPressed = [Bool](repeating: false, count: 4)
    init(keys: [Int], center: CGPoint, shift: CGFloat, mode: JoystickMode) {
        self.keys = keys
        self.center = center
        self.touch = center
        self.shift = shift / 4
        self.mode = mode
        for index in 0..<keys.count {
            let key = keys[index]
            ActionDispatcher.register(key: KeyCodeNames.keyCodes[key]!,
                                     handler: self.getPressedHandler(index: index))
        }
    }

    convenience init(data: Joystick) {
        self.init(
            keys: [
                data.upKeyCode,
                data.downKeyCode,
                data.leftKeyCode,
                data.rightKeyCode
            ],
            center: CGPoint(
                x: data.transform.xCoord.absoluteX,
                y: data.transform.yCoord.absoluteY),
            shift: data.transform.size.absoluteSize,
            mode: data.mode ?? Joystick.defaultMode)
    }

    func invalidate() {
        Toucher.touchcam(point: center, phase: UITouch.Phase.ended, tid: &id,
                         actionName: "KeyboardJoystick", keyName: "Keyboard")
    }

    func getPressedHandler(index: Int) -> (Bool) -> Void {
        if mode == .FIXED {
            return { pressed in
                self.updateTouch(index: index, pressed: pressed)
                self.handleFixed()
            }
        } else if mode == .FLOATING {
            return { pressed in
                self.updateTouch(index: index, pressed: pressed)
                self.handleFree()
            }
        } else {
            return { _ in
                // do nothing
            }
        }
    }

    func updateTouch(index: Int, pressed: Bool) {
        self.keyPressed[index] = pressed
        let isPlus = index & 1 != 0
        let realShift = isPlus ? shift : -shift
        if index > 1 {
            if pressed {
                touch.x = center.x + realShift
            } else if self.keyPressed[index ^ 1] {
                touch.x = center.x - realShift
            } else {
                touch.x = center.x
            }
        } else {
            if pressed {
                touch.y = center.y + realShift
            } else if self.keyPressed[index ^ 1] {
                touch.y = center.y - realShift
            } else {
                touch.y = center.y
            }
        }
    }

    func atCenter() -> Bool {
        return (center.x - touch.x).magnitude + (center.y - touch.y).magnitude < 8
    }

    func handleCommon(_ begin: () -> Void) {
        let moving = id != nil
        if atCenter() {
            if moving {
                Toucher.touchcam(point: touch, phase: UITouch.Phase.ended, tid: &id,
                                 actionName: "KeyboardJoystick", keyName: "Keyboard")
            }
        } else {
            if moving {
                Toucher.touchcam(point: touch, phase: UITouch.Phase.moved, tid: &id,
                                 actionName: "KeyboardJoystick", keyName: "Keyboard")
            } else {
                begin()
            }
        }
    }

    func handleFree() {
        handleCommon {
            Toucher.touchcam(point: self.center, phase: UITouch.Phase.began, tid: &id,
                             actionName: "KeyboardJoystick", keyName: "Keyboard")
            PlayInput.touchQueue.asyncAfter(deadline: .now() + 0.04, qos: .userInitiated) {
                if self.id == nil {
                    return
                }
                Toucher.touchcam(point: self.touch, phase: UITouch.Phase.moved, tid: &self.id,
                                 actionName: "KeyboardJoystick", keyName: "Keyboard")
            } // end closure
        }
    }

    func handleFixed() {
        handleCommon {
            Toucher.touchcam(point: self.touch, phase: UITouch.Phase.began, tid: &id,
                             actionName: "KeyboardJoystick", keyName: "Keyboard")
        }
    }
}

class CameraAction: Action {
    var swipeMove, swipeScale1, swipeScale2: SwipeAction
    static var swipeDrag = SwipeAction(actionName: "Drag", keyName: "ScrollWheel")
    var key: String!
    var center: CGPoint

    init(data: MouseArea) {
        self.key = data.keyName
        let centerX = data.transform.xCoord.absoluteX
        let centerY = data.transform.yCoord.absoluteY
        center = CGPoint(x: centerX, y: centerY)
        swipeMove = SwipeAction(actionName: "Camera", keyName: key)
        swipeScale1 = SwipeAction(actionName: "Zoom1", keyName: "ScrollWheel")
        swipeScale2 = SwipeAction(actionName: "Zoom2", keyName: "ScrollWheel")
        ActionDispatcher.register(key: key, handler: self.moveUpdated,
                                  priority: .CAMERA)
        ActionDispatcher.register(key: KeyCodeNames.scrollWheelScale,
                                  handler: self.scaleUpdated)
        ActionDispatcher.register(key: KeyCodeNames.scrollWheelDrag,
                                  handler: CameraAction.dragUpdated)
    }
    func moveUpdated(_ deltaX: CGFloat, _ deltaY: CGFloat) {
        swipeMove.move(from: {return center}, deltaX: deltaX, deltaY: deltaY)
    }

    func scaleUpdated(_ deltaX: CGFloat, _ deltaY: CGFloat) {
        let centerY = screen.height/2
        let centerX = screen.width/2
        swipeScale1.move(from: {
            CGPoint(x: centerX, y: centerY/2)
        }, deltaX: 0, deltaY: deltaY)

        swipeScale2.move(from: {
            CGPoint(x: centerX, y: centerY + (centerY/2))
        }, deltaX: 0, deltaY: -deltaY)
        // a move can't be longer than `centerY/16` due to the velocity limiter of `CameraAction`
        // so lifting off before two touches meet
        if swipeScale2.location.y - centerY < centerY/16 {
            swipeScale1.doLiftOff()
            swipeScale2.doLiftOff()
        }
    }

    static func dragUpdated(_ deltaX: CGFloat, _ deltaY: CGFloat) {
        swipeDrag.move(from: TouchscreenMouseEventAdapter.cursorPos, deltaX: deltaX * 4, deltaY: -deltaY * 4)
    }

    func invalidate() {
        swipeMove.invalidate()
        swipeScale1.invalidate()
        swipeScale2.invalidate()
    }
}

class SwipeAction: Action {
    var location: CGPoint = CGPoint.zero
    private var id: Int?
    let timer = DispatchSource.makeTimerSource(flags: [], queue: PlayInput.touchQueue)
    private let actionName: String, keyName: String
    init(actionName: String, keyName: String) {
        self.actionName = actionName
        self.keyName = keyName
        timer.schedule(deadline: DispatchTime.now() + 1, repeating: 0.1, leeway: DispatchTimeInterval.milliseconds(50))
        timer.setEventHandler(qos: .userInteractive, handler: self.checkEnded)
        timer.activate()
        timer.suspend()
    }

    deinit {
        timer.cancel()
    }

    func delay(_ delay: Double, closure: @escaping () -> Void) {
        let when = DispatchTime.now() + delay
        PlayInput.touchQueue.asyncAfter(deadline: when, execute: closure)
    }
    // Count swipe duration
    var counter = 0
    // if should wait before beginning next touch
    var cooldown = false
    var lastCounter = 0
    var shouldEdgeReset = false

    func checkEnded() {
        if self.counter == self.lastCounter {
            if self.counter < 4 {
                counter += 1
            } else {
                self.doLiftOff()
            }
        }
        self.lastCounter = self.counter
     }

    private func checkXYOutOfWindow(coordX: CGFloat, coordY: CGFloat) -> Bool {
        return coordX < 0 || coordY < 0 || coordX > screen.width || coordY > screen.height
    }

    /**
     get a multiplier to current velocity, so as to make the predicted coordinate inside window
     */
    private func getVelocityScaler(predictX: CGFloat, predictY: CGFloat,
                                   nowX: CGFloat, nowY: CGFloat) -> CGFloat {
        var scaler = 1.0
        if predictX < 0 {
            let scale =  (0 - nowX) / (predictX - nowX)
            scaler = min(scaler, scale)
        } else if predictX > screen.width {
            let scale =  (screen.width - nowX) / (predictX - nowX)
            scaler = min(scaler, scale)
        }

        if predictY < 0 {
            let scale =  (0 - nowY) / (predictY - nowY)
            scaler = min(scaler, scale)
        } else if predictY > screen.height {
            let scale =  (screen.height - nowY) / (predictY - nowY)
            scaler = min(scaler, scale)
        }
        return scaler
    }

    public func move(from: () -> CGPoint?, deltaX: CGFloat, deltaY: CGFloat) {
        if id == nil {
            if cooldown {
                return
            }
            guard let start = from() else {return}
            location = start
            counter = 0
            Toucher.touchcam(point: location, phase: UITouch.Phase.began, tid: &id,
                             actionName: actionName, keyName: keyName)
            timer.resume()
        } else {
            if shouldEdgeReset {
                doLiftOff()
                return
            }
            // 1. Put location update after touch action, so that final `end` touch has different location
            // 2. If `began` touched, do not `move` touch at the same time, otherwise the two may conflict
            Toucher.touchcam(point: self.location, phase: UITouch.Phase.moved, tid: &id,
                             actionName: actionName, keyName: keyName)
        }
        // Scale movement down, so that an edge reset won't cause a too short touch sequence
        var scaledDeltaX = deltaX
        var scaledDeltaY = deltaY
        // A scroll must have this number of touch events to get inertia
        let minTotalCounter = 16
        if counter < minTotalCounter {
            // Suppose the touch velocity doesn't change
            let predictX = self.location.x + CGFloat((minTotalCounter - counter)) * deltaX
            let predictY = self.location.y - CGFloat((minTotalCounter - counter)) * deltaY
            if checkXYOutOfWindow(coordX: predictX, coordY: predictY) {
                // Velocity needs scale down
                let scaler = getVelocityScaler(predictX: predictX, predictY: predictY,
                                               nowX: self.location.x, nowY: self.location.y)
                scaledDeltaX *= scaler
                scaledDeltaY *= scaler
            }
        }
        // count touch duration
        counter += 1
        self.location.x += scaledDeltaX
        self.location.y -= scaledDeltaY
        // Check if new location is out of window (position overflows)
        // May fail in some games if point moves out of window
        // If next touch is predicted out of window then this lift off instead
        if checkXYOutOfWindow(coordX: self.location.x + scaledDeltaX,
                              coordY: self.location.y - scaledDeltaY) {
            // Wait until next event to lift off, so as to maintain smooth scrolling speed
            shouldEdgeReset = true
        }
    }

    public func doLiftOff() {
        if id == nil {
            return
        }
        Toucher.touchcam(point: self.location, phase: UITouch.Phase.ended, tid: &id,
                         actionName: actionName, keyName: keyName)
        // Touch might somehow fail to end
        if id == nil {
            timer.suspend()
            delay(0.02) {
                self.cooldown = false
            }
            cooldown = true
            shouldEdgeReset = false
        }
    }

    func invalidate() {
        PlayInput.touchQueue.async(execute: self.doLiftOff)
    }
}

class FakeMouseAction: Action {
    var id: Int?
    var pos: CGPoint = CGPoint()
    public init() {
        ActionDispatcher.register(key: KeyCodeNames.fakeMouse, handler: buttonPressHandler)
        ActionDispatcher.register(key: KeyCodeNames.fakeMouse, handler: buttonLiftHandler)
    }

    func buttonPressHandler(xValue: CGFloat, yValue: CGFloat) {
        pos = CGPoint(x: xValue, y: yValue)
//        DispatchQueue.main.async {
//            Toast.showHint(title: "Fake mouse pressed", text: ["\(self.pos)"])
//        }
        Toucher.touchcam(point: pos, phase: UITouch.Phase.began, tid: &id,
                         actionName: "FakeMouse", keyName: "FakeMouse")
        ActionDispatcher.register(key: KeyCodeNames.fakeMouse,
                                  handler: movementHandler,
                                  priority: .DRAGGABLE)
    }

    func buttonLiftHandler(pressed: Bool) {
        if pressed {
            Toast.showHint(title: "Error", text: ["Fake mouse lift handler received a press event"])
            return
        }
//        DispatchQueue.main.async {
//            Toast.showHint(title: " lift Fake mouse", text: ["\(self.pos)"])
//        }
        Toucher.touchcam(point: pos, phase: UITouch.Phase.ended, tid: &id,
                         actionName: "FakeMouse", keyName: "FakeMouse")
        if id == nil {
            ActionDispatcher.unregister(key: KeyCodeNames.fakeMouse)
        }
    }

    func movementHandler(xValue: CGFloat, yValue: CGFloat) {
        pos.x = xValue
        pos.y = yValue
        Toucher.touchcam(point: pos, phase: UITouch.Phase.moved, tid: &id,
                         actionName: "FakeMouse", keyName: "FakeMouse")
    }

    func invalidate() {
        ActionDispatcher.unregister(key: KeyCodeNames.fakeMouse)
        Toucher.touchcam(point: pos ?? CGPoint(x: 10, y: 10),
                         phase: UITouch.Phase.ended, tid: &self.id,
                         actionName: "FakeMouse", keyName: "FakeMouse")
    }

}
