import GameController
import SwiftUI

let editor = EditorController.shared

class EditorController {

    static let shared = EditorController()

    let lock = NSLock()

    var focusedControl: ControlElement?

    var editorWindow: UIWindow?
    weak var previousWindow: UIWindow?
    var controls: [ControlElement] = []
    var view: EditorView! {editorWindow?.rootViewController?.view as? EditorView}

    private func initWindow() -> UIWindow {
        let window = UIWindow(windowScene: screen.windowScene!)
        window.rootViewController = EditorViewController(nibName: nil, bundle: nil)
        return window
    }

    private func addControlToView(control: ControlElement) {
        controls.append(control)
        view.addSubview(control.button)
        updateFocus(button: control.button)
    }

    public func updateFocus(button: Element) {
        view.setNeedsFocusUpdate()
        view.updateFocusIfNeeded()
        for cntrl in controls {
            cntrl.focus(false)
        }

        if let mod = button.model {
            mod.focus(true)
            focusedControl = mod
        }
    }

    public func switchMode() {
        lock.lock()
        if editorMode {
            EditorCircleMenu.shared.hide()
            saveButtons()
            editorWindow?.isHidden = true
            editorWindow?.windowScene = nil
            editorWindow?.rootViewController = nil
            // menu still holds this object until next responder hit test
            editorWindow = nil
            previousWindow?.makeKeyAndVisible()
            focusedControl = nil
            Toast.showHint(title: NSLocalizedString("hint.keymapSaved",
                                                    tableName: "Playtools", value: "Keymap Saved", comment: ""))
        } else {
            previousWindow = screen.keyWindow
            editorWindow = initWindow()
            editorWindow?.makeKeyAndVisible()
            showButtons()
            Toast.showHint(title: NSLocalizedString("hint.keymappingEditor.title",
                                                    tableName: "Playtools", value: "Keymapping Editor", comment: ""),
                           text: [NSLocalizedString("hint.keymappingEditor.content",
                                                    tableName: "Playtools",
                                value: "Click a button to edit its position or key bind\n"
                                        + "Click an empty area to open input menu", comment: "")],
                           notification: NSNotification.Name.playtoolsCursorWillHide)
        }
//        Toast.showOver(msg: "\(UIApplication.shared.windows.count)")
        lock.unlock()
    }

    var editorMode: Bool { !(editorWindow?.isHidden ?? true)}

    public func setKey(_ code: Int) {
        if editorMode {
            focusedControl?.setKey(code: code)
        }
    }

    public func setKey(_ name: String) {
        if editorMode {
            if name != "Mouse" || focusedControl is MouseAreaModel
                || focusedControl is JoystickModel
                || focusedControl is DraggableButtonModel {
                focusedControl?.setKey(name: name)
            }
        }
    }

    public func removeControl() {
        controls = controls.filter { $0 !== focusedControl }
        focusedControl?.remove()
    }

    func showButtons() {
        for button in keymap.keymapData.draggableButtonModels {
            let ctrl = DraggableButtonModel(data: button)
            addControlToView(control: ctrl)
        }
        for joystick in keymap.keymapData.joystickModel {
            let ctrl = JoystickModel(data: joystick)
            addControlToView(control: ctrl)
        }
        for mouse in keymap.keymapData.mouseAreaModel {
            let ctrl =
                MouseAreaModel(data: mouse)
            addControlToView(control: ctrl)
        }
        for button in keymap.keymapData.buttonModels {
            let ctrl = ButtonModel(data: button)
            addControlToView(control: ctrl)
        }
    }

    func saveButtons() {
        var keymapData = KeymappingData(bundleIdentifier: keymap.bundleIdentifier)
        controls.forEach {
            switch $0 {
            case let model as JoystickModel:
                keymapData.joystickModel.append(model.save())
            // subclasses must be checked first
            case let model as DraggableButtonModel:
                keymapData.draggableButtonModels.append(model.save())
            case let model as MouseAreaModel:
                keymapData.mouseAreaModel.append(model.save())
            case let model as ButtonModel:
                keymapData.buttonModels.append(model.save())
            default:
                break
            }
        }
        keymap.keymapData = keymapData
        controls = []
        view.subviews.forEach { $0.removeFromSuperview() }
    }

    public func addJoystick(_ center: CGPoint) {
        if editorMode {
            addControlToView(control: JoystickModel(data: Joystick(
                upKeyCode: GCKeyCode.keyW.rawValue,
                rightKeyCode: GCKeyCode.keyD.rawValue,
                downKeyCode: GCKeyCode.keyS.rawValue,
                leftKeyCode: GCKeyCode.keyA.rawValue,
                keyName: "Keyboard",
                transform: KeyModelTransform(
                    size: 20, xCoord: center.x.relativeX, yCoord: center.y.relativeY
                ),
                mode: .FIXED
            )))
        }
    }

    private func addButton(keyCode: Int, point: CGPoint) {
        if editorMode {
            addControlToView(control: ButtonModel(data: Button(
                keyCode: keyCode,
                keyName: KeyCodeNames.keyCodes[keyCode] ?? "Btn",
                transform: KeyModelTransform(
                    size: 5, xCoord: point.x.relativeX, yCoord: point.y.relativeY
                )
            )))
        }
    }

    public func addButton(_ toPoint: CGPoint) {
        self.addLMB(toPoint)
    }

    public func addLMB(_ toPoint: CGPoint) {
        self.addButton(keyCode: -1, point: toPoint)
    }

    public func addMouseJoystick(_ center: CGPoint) {
        if editorMode {
            addControlToView(
                control: JoystickModel(
                    data: Joystick(
                        upKeyCode: GCKeyCode.keyW.rawValue,
                        rightKeyCode: GCKeyCode.keyD.rawValue,
                        downKeyCode: GCKeyCode.keyS.rawValue,
                        leftKeyCode: GCKeyCode.keyA.rawValue,
                        keyName: "Mouse",
                        transform: KeyModelTransform(
                            size: 20, xCoord: center.x.relativeX, yCoord: center.y.relativeY
                        ),
                        mode: .FIXED
                    )
                )
            )
        }
    }

    public func addMouseArea(_ center: CGPoint) {
        if editorMode {
            addControlToView(control: MouseAreaModel(data: MouseArea(
                keyName: "Mouse",
                transform: KeyModelTransform(
                    size: 25, xCoord: center.x.relativeX, yCoord: center.y.relativeY
                )
            )))
        }
    }

    public func addDraggableButton(_ center: CGPoint, _ keyCode: Int) {
        if editorMode {
            addControlToView(control: DraggableButtonModel(data: Button(
                keyCode: keyCode,
                keyName: "Mouse",
                transform: KeyModelTransform(
                    size: 15, xCoord: center.x.relativeX, yCoord: center.y.relativeY
                )
            )))
        }
    }

    func updateEditorText(_ str: String) {
        view.label?.text = str
    }
}
