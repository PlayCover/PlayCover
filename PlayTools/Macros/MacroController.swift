import Foundation
import UIKit

@objc public class MacroController : NSObject {
    
    static let shared = MacroController()
    
    public var events : Array<Array<Any>> = []
    
    public var dispatches : Dictionary<Int, Array<Any>> = [:]
    
    public var isRecording = false
    
    public var globalTime = 0
    
    private let link = DisplayLink()
    
    @objc public func recordEvent(point : CGPoint, phase : UITouch.Phase, tid : Int){
        if(isRecording) {
            events.append([point.x, point.y, phase.rawValue, tid, globalTime])
        }
    }
    
    public func startRecording(){
        Toast.showOver(msg: "Started recording.")
        Toucher.reset()
        events = []
        isRecording = true
        globalTime = 0
    }
    
    public func stopRecording(){
        Toast.showOver(msg: "Stopped recording.")
        isLooped = false
        isRecording = false
        UserDefaults.standard.set(events, forKey: "playcover.macro")
    }
    
    var isReplaying = false
    var isLooped = false
    
    public func startReplayingLoop() {
        isLooped = true
        startReplaying()
    }
    
    public func startReplaying(){
        dispatches = [:]
        if let z = UserDefaults.standard.array(forKey: "playcover.macro"){
            for case let n as Array<Any> in z{
                dispatches[n[4] as! Int] = [CGPoint(x: n[0] as! CGFloat,y: n[1] as! CGFloat) ,UITouch.Phase.init(rawValue: n[2] as! Int), n[3] as! Int]
            }
        } else {
            for n in events{
                dispatches[n[4] as! Int] = [CGPoint(x: n[0] as! CGFloat,y: n[1] as! CGFloat) ,UITouch.Phase.init(rawValue: n[2] as! Int), n[3] as! Int]
            }
        }
        if !dispatches.isEmpty {
            Toucher.reset()
            globalTime = 0
            endTime = dispatches.keys.max()! + 1
            isReplaying = true
        } else {
            Toast.showOver(msg: "Macro is empty! Please, record or import.")
        }
    }
    
    public func stopReplaying(){
        if isReplaying {
            isReplaying = false
            dispatches = [:]
            Toucher.reset()
        }
    }
    
    private var endTime = 0
    
    @objc func dispatchTouch(){
        if(globalTime > endTime){
            isReplaying = false
            globalTime = 0
            endTime = 0
            if isLooped {
                startReplaying()
            }
        }
        if let p = dispatches[globalTime]{
            Toucher.touchcam(point: p[0] as! CGPoint, phase:  p[1] as! UITouch.Phase, tid: p[2] as! Int)
        }
    }
}

class DisplayLink {
    @objc func displayRefreshed(displayLink: CADisplayLink) {
        if(MacroController.shared.isRecording){
            MacroController.shared.globalTime+=1
        }
        if(MacroController.shared.isReplaying){
            MacroController.shared.dispatchTouch()
            MacroController.shared.globalTime+=1
        }
    }
    init() {
        let displayLink = CADisplayLink(target: self, selector: #selector(displayRefreshed(displayLink:)))
        displayLink.add(to: .main, forMode: .default)
    }
}

