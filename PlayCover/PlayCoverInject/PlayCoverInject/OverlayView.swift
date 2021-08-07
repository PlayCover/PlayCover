
import GameController

class OverlayController {

    static let shared = OverlayController()
    private init() { }
    
    var focusedControl : ControlModel? = nil
    var controls : Array<ControlModel> = []
    var overlayView = OverlayView(s : 0)
    var realTimeControls : Array<Array<CGFloat>>? = nil
    
    public func addControlToView(control : ControlModel){
        controls.append(control)
        overlayView.addSubview(control.button)
        overlayView.setNeedsFocusUpdate()
        overlayView.updateFocusIfNeeded()
    }
    
    public func updateFocus(button : UIButton){
        overlayView.setNeedsFocusUpdate()
        overlayView.updateFocusIfNeeded()
        overlayView.bringSubviewToFront(button)
    }
    
    public func changeState(){
        MouseEmitter.shared.setup = true
        if(overlayView.isUserInteractionEnabled){
            MouseEmitter.shared.setActive(active: true)
            overlayView.isUserInteractionEnabled = false
            overlayView.removeFromSuperview()
            saveButtons()
            InputController.updateControls()
        } else{
            MouseEmitter.shared.setActive(active: false)
            overlayView.isUserInteractionEnabled = true
            InputController.window()?.addSubview(overlayView)
            if(overlayView.subviews.count == 0){
                initAllButtons()
            }
        }
    }
    
    func addGestureRecognizer(recognizer : UIPanGestureRecognizer){
        overlayView.addGestureRecognizer(recognizer)
    }
    
    func isEnabled() -> Bool{
        return overlayView.isUserInteractionEnabled
    }
    
    func dismissAnyAlertControllerIfPresent() {
        guard let window :UIWindow = UIApplication.shared.keyWindow , var topVC = window.rootViewController?.presentedViewController else {return}
        while topVC.presentedViewController != nil  {
            topVC = topVC.presentedViewController!
        }
    }
    
    public func handlePress(presses: Set<UIPress>){
        // disable if disabled
        if let key = presses.first?.key {
            if(key.modifierFlags.contains(.control)){
                switch key.keyCode {
                case .keyboardP:
                    changeState()
                case .keyboardN:
                    addButton()
                case .keyboardU:
                    Recorder.shared.startRecord()
                case .keyboardI:
                    Recorder.shared.stopRecord()
                case .keyboardO:
                    Recorder.shared.playback()
                case .keyboardJ:
                    addJoystick()
                case .keyboardM:
                    addMouseArea()
                case .keyboardK:
                    addSkillShot()
                case .keyboardDeleteOrBackspace:
                    removeControl()
                case .keyboardHyphen:
                    focusedControl?.resize(down: true)
                case .keyboardEqualSign:
                    focusedControl?.resize(down: false)
                case .keyboardW:
                    focusedControl?.move(dy: CGFloat(-10), dx: CGFloat(0))
                case .keyboardS:
                    focusedControl?.move(dy: CGFloat(10), dx: CGFloat(0))
                case .keyboardA:
                    focusedControl?.move(dy: CGFloat(0), dx: CGFloat(-10))
                case .keyboardD:
                    focusedControl?.move(dy: CGFloat(0), dx: CGFloat(10))
                default:
                    break
                }
            } else if(key.modifierFlags.contains(.shift)){
                switch key.keyCode {
                case .keyboardL:
                    focusedControl?.setKeyCodes(keys: [-1])
                    return
                case .keyboardR:
                    focusedControl?.setKeyCodes(keys: [-2])
                    return
                case .keyboardM:
                    focusedControl?.setKeyCodes(keys: [-3])
                    return
                default:
                    break
                }
                focusedControl?.setKeyCodes(keys: [GCKeyCode.leftShift.rawValue])
            }
            else {
                if(overlayView.isUserInteractionEnabled){
                    focusedControl?.setKeyCodes(keys: [key.keyCode.rawValue])
                }
            }
        }
    }
    
    public func removeControl(){
        controls = controls.filter { $0 === focusedControl }
        focusedControl?.remove()
    }
    
    
     func initAllButtons(){
        if let buttons = UserDefaults.standard.array(forKey: "playcover.layout"){
            if(buttons.count > 0){
                for case let btn as Array<CGFloat> in buttons{
                    ControlModel.createControlFromData(data: btn)
                }
            }
        }
    }
    
    private func saveButtons(){
        if(overlayView.subviews.count > 0){
                var updatedLayout = Array<Array<CGFloat>>()
                for model in controls{
                    updatedLayout.append(model.save())
                }
            realTimeControls = updatedLayout
            UserDefaults.standard.set(updatedLayout, forKey: "playcover.layout")
        } else{
            realTimeControls = []
            UserDefaults.standard.set([], forKey: "playcover.layout")
        }
        
    }
    
    private var displayMult = CGFloat(max(Values.screenWidth, Values.screenHeight) / 50) * 3

    public func addJoystick(){
        if(overlayView.isUserInteractionEnabled){
            JoystickModel(data: ControlData(keyCodes: [GCKeyCode.keyW.rawValue, GCKeyCode.keyS.rawValue, GCKeyCode.keyA.rawValue, GCKeyCode.keyD.rawValue], size: displayMult * 3, x: MouseController.overallMousePosition.x, y: MouseController.overallMousePosition.y))
        }
    }
    
    public func addButton(){
        if(overlayView.isUserInteractionEnabled){
            ButtonModel(data: ControlData(keyCodes: [-1], size: displayMult, x: MouseController.overallMousePosition.x, y: MouseController.overallMousePosition.y, parent: nil))
        }
    }
    
    public func addMouseArea(){
        if(overlayView.isUserInteractionEnabled){
            MouseAreaModel(data: ControlData(size: displayMult * 5, x: MouseController.overallMousePosition.x, y: MouseController.overallMousePosition.y))
        }
    }
    
    public func addSkillShot(){
        if(overlayView.isUserInteractionEnabled){
            SkillShotModel(data: ControlData(keyCodes: [-1], size: displayMult, x: MouseController.overallMousePosition.x, y: MouseController.overallMousePosition.y, sensivity: CGFloat(50)))
        }
    }
    
}

class OverlayView: UIView {
    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        if let btn = OverlayController.shared.focusedControl?.button {
            return [btn]
        }
        return [self]
    }
    init(s : Int) {
        super.init(frame: .zero)
        self.setX(x: 0)
        self.setY(y: 0)
        self.setHeight(height: Values.screenHeight)
        self.setWidth(width:  Values.screenWidth)
        self.isUserInteractionEnabled = false
    }
    
    @objc func dragged(sender: UIButton!) {
        if case let button = sender as! Element{
            OverlayController.shared.focusedControl = button.model
            OverlayController.shared.updateFocus(button: sender)
        }
    }
    
    @objc func pressed(sender: UIButton!) {
        if case let button = sender as! Element{
            OverlayController.shared.focusedControl = button.model
            OverlayController.shared.updateFocus(button: sender)
        }
    }
    
    @objc func draggedView(_ sender:UIPanGestureRecognizer){
        if (OverlayController.shared.focusedControl?.button) != nil{
            OverlayController.shared.updateFocus(button: OverlayController.shared.focusedControl!.button)
            let translation = sender.translation(in: self)
            OverlayController.shared.focusedControl?.move(dy: translation.y, dx:translation.x)
        }
        sender.setTranslation(CGPoint.zero, in: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}





