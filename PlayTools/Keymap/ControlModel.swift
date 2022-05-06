
import GameController

@objc class ControlData : NSObject {
    
    var keyCodes : [Int]
    var size : CGFloat
    var x : CGFloat
    var y : CGFloat
    var parent : ControlModel?
    
    init(keyCodes : [Int], size : CGFloat, x : CGFloat, y : CGFloat, parent : ControlModel?) {
        self.keyCodes = keyCodes
        self.size = size
        self.x = x
        self.y = y
        self.parent = parent
    }
    
    init(keyCodes : [Int], size : CGFloat, x : CGFloat, y : CGFloat, sensivity : CGFloat) {
        self.keyCodes = keyCodes
        self.size = size
        self.x = x
        self.y = y
    }
    
    init(keyCodes : [Int], parent : ControlModel) {
        self.keyCodes = keyCodes
        self.size = parent.data.size  / 3
        self.x = 0
        self.y = 0
        self.parent = parent
    }
    
    init(size : CGFloat, x : CGFloat, y : CGFloat) {
        self.keyCodes = [0]
        self.size = size
        self.x = x
        self.y = y
        self.parent = nil
    }
    
    init(keyCodes : [Int], size : CGFloat, x : CGFloat, y : CGFloat) {
        self.keyCodes = keyCodes
        self.size = size
        self.x = x
        self.y = y
        self.parent = nil
    }
}

class Element : UIButton {
    var model : ControlModel? = nil
}

class ControlModel {
    
    static func createControlFromData(data: Array<CGFloat>) -> ControlModel? {
        if(data.count == 4){
            return ButtonModel(data: ControlData(keyCodes: [Int(data[0])] , size: data[3], x: data[1], y: data[2], parent: nil))
        } else if(data.count == 8){
            return JoystickModel(data: ControlData(keyCodes: [Int(data[0]),Int(data[1]), Int(data[2]),Int(data[3])], size: data[6], x: data[4], y: data[5]))
        } else if(data.count == 2){
            return MouseAreaModel(data: ControlData(size: 25, x: data[0], y: data[1]))
        }
        return nil
    }
    
    var data: ControlData
    var button: Element
    
    func save() -> Array<CGFloat>{
        return []
    }
    
    func update() {
        
    }
    
    func focus(_ focus : Bool){
        
    }
    
    func unfocusChildren(){
        
    }
    
    init(data : ControlData) {
        button = Element()
        self.data = data
        button.model = self
        button.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        button.addTarget(editor.view, action: #selector(editor.view.pressed(sender:)), for: .touchUpInside)
        let recognizer = UIPanGestureRecognizer(target: editor.view, action: #selector(editor.view.dragged(_:)))
        button.addGestureRecognizer(recognizer)
        button.isUserInteractionEnabled = true
    }
    
    func remove(){
        self.button.removeFromSuperview()
    }
    
    func move(dy : CGFloat, dx : CGFloat){
        let nx = button.center.x + dx
        let ny = button.center.y + dy
        if nx > 0 && nx < screen.width {
            data.x = nx.relativeX
        }
        if ny > 0 && ny < screen.height {
            data.y = ny.relativeY
        }
        update()
    }
    
    func resize(down : Bool){
        let mod = down ? 0.9 : 1.1
        data.size = (button.frame.width * CGFloat(mod)).relativeSize
        update()
    }
    
    func setKeyCodes(keys : [Int]) {
        
    }
    
}

class ButtonModel : ControlModel {
    
    override init(data: ControlData) {
        super.init(data: data)
        update()
    }
    
    override func save() -> Array<CGFloat>{
        return [CGFloat(data.keyCodes[0]), data.x , data.y, data.size]
    }
    
    override func update() {
        self.setKeyCodes(keys: data.keyCodes)
        button.setWidth(width: data.size.absoluteSize)
        button.setHeight(height: data.size.absoluteSize)
        button.setX(x: data.x.absoluteX)
        button.setY(y: data.y.absoluteY)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width;
        button.clipsToBounds = true
        button.titleLabel?.minimumScaleFactor = 0.01
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.textAlignment = .center
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    }
    
    override func focus(_ focus : Bool){
        if focus {
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.systemPink.cgColor
            button.setNeedsDisplay()
        } else {
            button.layer.borderWidth = 0
            button.setNeedsDisplay()
        }
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

class RMBModel : ButtonModel {
    
    
    override func setKeyCodes(keys : [Int]){
        data.keyCodes = [-2]
        button.setTitle("RMB", for: UIControl.State.normal)
    }
    
}

class LMBModel : ButtonModel {
    
    
    override func setKeyCodes(keys : [Int]){
        data.keyCodes = [-1]
        button.setTitle("LMB", for: UIControl.State.normal)
    }
    
}

class MMBModel : ButtonModel {
    
    
    override func setKeyCodes(keys : [Int]){
        data.keyCodes = [-3]
        button.setTitle("MMB", for: UIControl.State.normal)
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
        data.parent?.button.model?.move(dy: dy, dx: dx)
    }
    
    override func resize(down: Bool) {
        if let parentButton = data.parent?.button{
            parentButton.model?.resize(down: down)
        }
    }
    
    override func focus(_ focus : Bool){
        if focus {
            data.parent?.unfocusChildren()
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.systemPink.cgColor
            button.setNeedsDisplay()
        } else {
            button.layer.borderWidth = 0
            button.setNeedsDisplay()
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
        data.append(contentsOf: [self.data.x, self.data.y,self.data.size, self.data.size])
        return data
    }
    
    override init(data: ControlData) {
        super.init(data: data)
        update()
    }
    
    override func update() {
        button.setWidth(width: data.size.absoluteSize)
        button.setHeight(height: data.size.absoluteSize)
        button.setX(x: data.x.absoluteX)
        button.setY(y: data.y.absoluteY)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width;
        button.clipsToBounds = true
        if data.keyCodes.count == 4 && joystickButtons.count == 0 {
            for i in data.keyCodes{
                joystickButtons.append(JoystickButtonModel(data: ControlData(keyCodes:[i], parent: self)))
            }
        }
        changeButtonsSize()
    }
    
    override func focus(_ focus : Bool){
        if focus {
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.systemPink.cgColor
            button.setNeedsDisplay()
        } else {
            button.layer.borderWidth = 0
            button.setNeedsDisplay()
            unfocusChildren()
        }
    }
    
    override func unfocusChildren() {
        for joystickButton in joystickButtons {
            joystickButton.focus(false)
        }
    }
    
    override func resize(down : Bool){
        let mod = down ? 0.9 : 1.1
        data.size = (button.frame.width * CGFloat(mod)).relativeSize
        update()
    }
    
    func changeButtonsSize(){
        let btns = button.subviews
        let buttonSize = data.size.absoluteSize / 3
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

class MouseAreaModel : ControlModel {
    
    override func save() -> Array<CGFloat>{
        return [data.x, data.y]
    }
    
    override func focus(_ focus : Bool){
        if focus {
            button.layer.borderWidth = 3
            button.layer.borderColor = UIColor.systemPink.cgColor
            button.setNeedsDisplay()
        } else {
            button.layer.borderWidth = 0
            button.setNeedsDisplay()
        }
    }
    
    override func update() {
        button.setWidth(width: data.size.absoluteSize)
        button.setHeight(height: data.size.absoluteSize)
        button.setX(x: data.x.absoluteX)
        button.setY(y: data.y.absoluteY)
        button.layer.cornerRadius = 0.5 * button.bounds.size.width;
        button.clipsToBounds = true
    }
    
    override init(data: ControlData) {
        super.init(data: data)
        update()
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
