
import GameController

@objc class ControlData : NSObject {
    
    var keyCodes : [Int]
    var size : CGFloat
    var x : CGFloat
    var y : CGFloat
    var parent : ControlModel?
    var sensivityX : CGFloat
    
    
    init(keyCodes : [Int], size : CGFloat, x : CGFloat, y : CGFloat, parent : ControlModel?) {
        self.keyCodes = keyCodes
        self.size = size
        self.x = x
        self.y = y
        self.parent = parent
        self.sensivityX = 0
    }
    
    init(keyCodes : [Int], size : CGFloat, x : CGFloat, y : CGFloat, sensivity : CGFloat) {
        self.keyCodes = keyCodes
        self.size = size
        self.x = x
        self.y = y
        self.sensivityX = sensivity
    }
    
    init(keyCodes : [Int], parent : ControlModel) {
        self.keyCodes = keyCodes
        self.size = parent.data.size  / 3
        self.x = 0
        self.y = 0
        self.parent = parent
        self.sensivityX = 0
    }
    
    init(size : CGFloat, x : CGFloat, y : CGFloat) {
        self.keyCodes = [0]
        self.size = size
        self.x = x
        self.y = y
        self.parent = nil
        self.sensivityX = 0
    }
    
    init(keyCodes : [Int], size : CGFloat, x : CGFloat, y : CGFloat) {
        self.keyCodes = keyCodes
        self.size = size
        self.x = x
        self.y = y
        self.parent = nil
        self.sensivityX = 0
    }
}

class Element : UIButton {
    var model : ControlModel? = nil
}

class ControlModel {
    
    static func createControlFromData(data: Array<CGFloat>) {
        if(data.count == 4){
            ButtonModel(data: ControlData(keyCodes: [Int(data[0])] , size: data[3], x: data[1], y: data[2], parent: nil))
        } else if(data.count == 8){
            JoystickModel(data: ControlData(keyCodes: [Int(data[0]),Int(data[1]), Int(data[2]),Int(data[3])], size: data[6] * CGFloat(2), x: data[4], y: data[5]))
        } else if(data.count == 3){
            MouseAreaModel(data: ControlData(size: data[0], x: data[1], y: data[2]))
        } else if(data.count == 5){
            SkillShotModel(data: ControlData(keyCodes: [Int(data[0])] , size: data[3], x: data[1], y: data[2], sensivity: data[4]))
        }
    }
    
    var data: ControlData
    var button: Element
    
    func save() -> Array<CGFloat>{
        return []
    }
    
    init(data : ControlData) {
        button = Element()
        self.data = data
        button.model = self
        button.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        button.addTarget(OverlayController.shared.overlayView, action: #selector(OverlayController.shared.overlayView.pressed(sender:)), for: .touchUpInside)
        button.addTarget(OverlayController.shared.overlayView, action: #selector(OverlayController.shared.overlayView.dragged(sender:)), for: .touchDragInside)
        OverlayController.shared.addGestureRecognizer(recognizer: UIPanGestureRecognizer(target: OverlayController.shared.overlayView, action: #selector(OverlayController.shared.overlayView.draggedView(_:))))
        button.isUserInteractionEnabled = true
    }
    
     func remove(){
        self.button.removeFromSuperview()
     }
    
    func move(dy : CGFloat, dx : CGFloat){
                let nx = button.center.x + dx
                let ny = button.center.y + dy
        if(nx > 0 && nx < Values.screenWidth){
                    button.setX(x: nx)
                }
        if(ny > 0 && ny < Values.screenHeight){
                    button.setY(y: ny)
                }
    }
    
    func resize(down : Bool){
                let mod = down ? 0.9 : 1.1
                button.setWidth(width: button.frame.width * CGFloat(mod))
                button.setHeight(height: button.frame.height * CGFloat(mod))
                button.layer.cornerRadius = 0.5 * button.bounds.size.width;
    }
    
    func setKeyCodes(keys : [Int]) {
        
    }
    
}

class ButtonModel : ControlModel {

    override init(data: ControlData) {
        super.init(data: data)
        self.setKeyCodes(keys: data.keyCodes)
        button.setWidth(width: data.size)
        button.setHeight(height: data.size)
        button.setX(x: data.x)
        button.setY(y: data.y)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width;
        button.clipsToBounds = true
        button.titleLabel?.minimumScaleFactor = 0.01
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.textAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        OverlayController.shared.addControlToView(control: self)
        
    }
    
    override func save() -> Array<CGFloat>{
        return [CGFloat(data.keyCodes[0]), button.center.x, button.center.y, button.frame.size.width]
    }
    
    override func setKeyCodes(keys : [Int]){
        data.keyCodes = keys
        if let title = KeyCodeNames.keyCodes[keys[0]]{
            button.setTitle(title, for: UIControl.State.normal)
        } else{
            button.setTitle("Btn", for: UIControl.State.normal)
        }
    }
    
}

class SkillShotModel : ButtonModel{
    override func save() -> Array<CGFloat>{
        return [CGFloat(data.keyCodes[0]), button.center.x, button.center.y, button.frame.size.width, CGFloat(50)]
    }
}

class JoystickButtonModel : ControlModel {

    override init(data: ControlData) {
        super.init(data: data)
        self.setKeyCodes(keys: data.keyCodes)
        data.parent?.button.addSubview(button)
    }
    
    override func remove(){
        data.parent?.button.removeFromSuperview()
    }
    
    override func setKeyCodes(keys : [Int]){
        data.keyCodes = keys
        if let title = KeyCodeNames.keyCodes[keys[0]]{
            button.setTitle(title, for: UIControl.State.normal)
        } else{
            button.setTitle("Btn", for: UIControl.State.normal)
        }
    }
    
    override func move(dy : CGFloat, dx : CGFloat){
        if let btn = data.parent?.button{
                    let nx =  btn.center.x + dx
                    let ny =  btn.center.y + dy
                    if(nx > 0 && nx < Values.screenWidth){
                        btn.setX(x: nx)
                    }
                    if(ny > 0 && ny < Values.screenWidth){
                        btn.setY(y: ny)
                    }
        }
    }
    
    override func resize(down: Bool) {
        if let parentButton = data.parent?.button{
            let mod = down ? 0.9 : 1.1
            let oldX = parentButton.center.x
            let oldY = parentButton.center.y
            parentButton.setWidth(width: parentButton.frame.width * CGFloat(mod))
            parentButton.setHeight(height: parentButton.frame.height * CGFloat(mod))
            parentButton.layer.cornerRadius = 0.5 * parentButton.bounds.size.width;
            if case let joy as JoystickModel = data.parent{
                joy.changeButtonsSize()
            }
            parentButton.setX(x: oldX)
            parentButton.setY(y: oldY)
        }
    }
    
}

class JoystickModel : ControlModel{
    
    var joystickButtons = Array<JoystickButtonModel>()
    
    override func save() -> Array<CGFloat> {
        var data = Array<CGFloat>()
        for j in joystickButtons{
            data.append(CGFloat(j.data.keyCodes[0]))
        }
        data.append(contentsOf: [button.center.x, button.center.y, (button.frame.width / 2), (button.frame.width / 4)])
        return data
    }
    
    override init(data: ControlData) {
        super.init(data: data)
        button.setWidth(width: data.size)
        button.setHeight(height: data.size)
        button.setX(x: data.x)
        button.setY(y: data.y)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width;
        button.clipsToBounds = true
        OverlayController.shared.addControlToView(control: self)
        if(data.keyCodes.count == 4){
            for i in data.keyCodes{
                joystickButtons.append(JoystickButtonModel(data: ControlData(keyCodes:[i], parent: self)))
            }
        }
        changeButtonsSize()
    }
    
     func changeButtonsSize(){
        let btns = button.subviews
        let buttonSize = button.frame.width / 3
        let x1 = (button.frame.width / 2) - buttonSize / 2
        let y1 = buttonSize / 4.5
        let x2 = (button.frame.width / 2) - buttonSize / 2
        let y2 = button.frame.width - buttonSize - buttonSize / 4.5
            if(btns.count == 4){
                btns[0].frame = CGRect(x: x1, y: y1 , width: buttonSize , height: buttonSize)
                btns[1].frame = CGRect(x: x2, y: y2 , width: buttonSize , height: buttonSize)
                btns[2].frame = CGRect(x: y1, y: x1 , width: buttonSize , height: buttonSize)
                btns[3].frame = CGRect(x: y2, y: x2 , width: buttonSize , height: buttonSize)
                btns[0].layer.cornerRadius = 0.5 * btns[0].bounds.size.width;
                btns[1].layer.cornerRadius = 0.5 * btns[1].bounds.size.width;
                btns[2].layer.cornerRadius = 0.5 * btns[2].bounds.size.width;
                btns[3].layer.cornerRadius = 0.5 * btns[3].bounds.size.width;
            }
        
    }
}

class MouseAreaModel : ControlModel{
    
    override func save() -> Array<CGFloat>{
        return [button.frame.size.width, button.center.x, button.center.y]
    }

    override init(data: ControlData) {
        super.init(data: data)
        button.setWidth(width: data.size)
        button.setHeight(height: data.size)
        button.setX(x: data.x)
        button.setY(y: data.y)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width;
        button.clipsToBounds = true
        OverlayController.shared.addControlToView(control: self)
    }
    
}

extension UIView {
    
    func setX(x:CGFloat) {
        self.center = CGPoint(x: x,y: self.center.y)
    }
    
    func setY(y:CGFloat) {
        self.center = CGPoint(x: self.center.x,y: y)
    }
    
    func setWidth(width:CGFloat) {
        var frame:CGRect = self.frame
        frame.size.width = width
        self.frame = frame
    }
    
    func setHeight(height:CGFloat) {
        var frame:CGRect = self.frame
        frame.size.height = height
        self.frame = frame
    }
}
