//
//  ActionDispatcher.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/16.
//

import Foundation
import Atomics

// If the same key is mapped to multiple different tasks, distinguish by priority
public enum ActionDispatchPriority: Int {
    case DRAGGABLE
    case DEFAULT
    case CAMERA
}

// This class reads keymap and thereby dispatch events

public class ActionDispatcher {
    static private let keymapVersion = "2.0."
    static private var actions = [Action]()
    static private var buttonHandlers: [String: [(Bool) -> Void]] = [:]

    static private let PRIORITY_COUNT = 3
    // You can't put more than 8 cameras or 8 joysticks in a keymap right?
    static private let MAPPING_COUNT_PER_PRIORITY = 8
    static private let directionPadHandlers: [[ManagedAtomic<AtomicHandler>]] = Array(
        (0..<PRIORITY_COUNT).map({_ in
            (0..<MAPPING_COUNT_PER_PRIORITY).map({_ in ManagedAtomic<AtomicHandler>(.EMPTY)})
        })
    )

    static private func clear() {
        invalidateActions()
        actions = []
        buttonHandlers.removeAll(keepingCapacity: true)
        directionPadHandlers.forEach({ handlers in
            handlers.forEach({ handler in
                handler.store(.EMPTY, ordering: .relaxed)
            })
        })
    }

    // Backend interfaces

    // This should be called whenever keymap may change
    static public func build() {
        clear()

        actions.append(FakeMouseAction())

        // current keymap version is 2.0.x.
        // in future, keymap format will be upgraded.
        // PlayTools would maintain limited backwards compatibility.
        // Meanwhile, keymap format upgrade would be rare.
        if !keymap.keymapData.version.hasPrefix(keymapVersion) {
            DispatchQueue.main.asyncAfter(
                deadline: .now() + .seconds(5)) {
                    Toast.showHint(title: "Keymap format too new",
                       text: ["Current keymap version \(keymap.keymapData.version)" +
                              " is too new and cannot be recognized\n" +
                             "For protection of your data, keymap is not loaded\n" +
                             "Please upgrade PlayCover, " +
                              "or import an older version of keymap (requires \(keymapVersion)x"])
            }
            return
        }

        for button in keymap.keymapData.buttonModels {
            actions.append(ButtonAction(data: button))
        }

        for draggableButton in keymap.keymapData.draggableButtonModels {
            actions.append(DraggableButtonAction(data: draggableButton))
        }

        for mouse in keymap.keymapData.mouseAreaModel {
            actions.append(CameraAction(data: mouse))
        }

        for joystick in keymap.keymapData.joystickModel {
            // Left Thumbstick, Right Thumbstick, Mouse
            if JoystickModel.isAnalog(joystick) {
                actions.append(ContinuousJoystickAction(data: joystick))
            } else { // Keyboard
                actions.append(JoystickAction(data: joystick))
            }
        }
        // `cursorHideNecessary` is used to disable `option` toggle when there is no mouse mapping
        // but in the case this new feature disabled, `option` should always function.
        // this variable is set here to be checked for mouse mapping later.
        cursorHideNecessary =
        (getDispatchPriority(key: KeyCodeNames.leftMouseButton) ?? .DRAGGABLE) != .DRAGGABLE ||
        (getDispatchPriority(key: KeyCodeNames.mouseMove) ?? .DRAGGABLE) != .DRAGGABLE
    }

    static public func register(key: String, handler: @escaping (Bool) -> Void) {
        // this function is called when setting up `button` type of mapping
        if buttonHandlers[key] == nil {
            buttonHandlers[key] = []
        }
        buttonHandlers[key]!.append(handler)
    }

    static public func register(key: String,
                                handler: @escaping (CGFloat, CGFloat) -> Void,
                                priority: ActionDispatchPriority = .DEFAULT) {
        let atomicHandler = directionPadHandlers[priority.rawValue].first(where: { handler in
            handler.load(ordering: .relaxed).key == key
        }) ??
        directionPadHandlers[priority.rawValue].first(where: { handler in
            handler.load(ordering: .relaxed).key.isEmpty
        })
//        DispatchQueue.main.async {
//            if screen.keyWindow == nil {
//                return
//            }
//            Toast.showHint(title: "register",
//               text: ["key: \(key), atomicHandler: \(String(describing: atomicHandler))"])
//        }
        atomicHandler?.store(AtomicHandler(key, handler), ordering: .releasing)
    }

    static public func unregister(key: String) {
        // Only draggable can be unregistered
        let atomicHandler = directionPadHandlers[ActionDispatchPriority.DRAGGABLE.rawValue].first(where: { handler in
            handler.load(ordering: .relaxed).key == key
        })
//        DispatchQueue.main.async {
//            if screen.keyWindow == nil {
//                return
//            }
//            Toast.showHint(title: "unregister",
//               text: ["key: \(key), atomicHandler: \(String(describing: atomicHandler))"])
//        }
        atomicHandler?.store(.EMPTY, ordering: .releasing)
    }

    // Frontend interfaces

    static public var cursorHideNecessary = true

    /**
        Lift off (release) all actions' touch points.
        Would be called during mode switching where target mode shouldn't have any touch remain.
    */
    static public func invalidateActions() {
        for action in actions {
            // This is just a rescue feature, in case any key stuck pressed for any reason
            // Might be called on control mode state transition
            action.invalidate()
        }
    }

    /**
        Lift off (release) touch points of actions that moves freely under control of the
        user. (e.g. camera control action) Would be called during every mode switching
        where `invalidateActions` is not called. In such scenario button-type
        actions are not released, because users may continue using them across different modes.
        (e.g. holding W while unhiding cursor to click something)

        But non-button-type actions (e.g. camera control action, fake mouse action) are unlikely
        used across modes. If they're not released, they would interfere with and ruin the game's
        camera control (becomes random zoom in zoom out)
    */
    static public func invalidateNonButtonActions() {
        for action in actions
        where !(action is ButtonAction || action is JoystickAction) {
            action.invalidate()
        }
    }

    static public func getDispatchPriority(key: String) -> ActionDispatchPriority? {
        if let priority = directionPadHandlers.firstIndex(where: { handlers in
            handlers.contains(where: { handler in
                handler.load(ordering: .acquiring).key == key
            })
        }) {
//            Toast.showHint(title: "\(key) priority", text: ["\(priority)"])
            return ActionDispatchPriority(rawValue: priority)
        }

        if buttonHandlers[key] != nil {
            return .DEFAULT
        }
        return nil
    }

    static public func dispatch(key: String, pressed: Bool) -> Bool {
        guard let handlers = buttonHandlers[key] else {
            return false
        }
        var mapped = false
        for handler in handlers {
            PlayInput.touchQueue.async(qos: .userInteractive, execute: {
                handler(pressed)
            })
            mapped = true
        }
        // return value matters. A false value makes a beep sound
        return mapped
    }

    static public func dispatch(key: String, valueX: CGFloat, valueY: CGFloat) -> Bool {
        for priority in 0..<PRIORITY_COUNT {
            if let handler = directionPadHandlers[priority].first(where: { handler in
                handler.load(ordering: .acquiring).key == key
            }) {
                PlayInput.touchQueue.async(qos: .userInteractive, execute: {
                    handler.load(ordering: .relaxed).handle(valueX, valueY)
                })
                return true
            }
        }
        return false
    }
}

private final class AtomicHandler: AtomicReference {
    static fileprivate let EMPTY = AtomicHandler("", {_, _ in })
    let key: String
    let handle: (CGFloat, CGFloat) -> Void
    init(_ key: String, _ handle: @escaping (CGFloat, CGFloat) -> Void) {
        self.key = key
        self.handle = handle
    }
}
