import Foundation
import UIKit

class DisplayLink {
    @objc func displayRefreshed(displayLink: CADisplayLink) {
        if(Recorder.shared.isRecording){
            Recorder.shared.globalTime+=1
        }
        if(Recorder.shared.isPlayback){
            Recorder.shared.dispatchTouch()
            Recorder.shared.globalTime+=1
        }
    }
  init() {
    let displayLink = CADisplayLink(target: self, selector: #selector(displayRefreshed(displayLink:)))
      displayLink.add(to: .main, forMode: .default)
    }
  }

@objc public class Recorder : NSObject {
    
    static let shared = Recorder()
    
    public var recordingButton : Array<Array<Any>> = []
    
    public var dispatches : Dictionary<Int, Array<Any>> = [:]
    
    public var isRecording = false
    
    public var globalTime = 0
    
    private let link = DisplayLink()
    
    @objc public func recordButton(point : CGPoint, phase : UITouch.Phase, tid : Int){
        if(isRecording) {
            recordingButton.append([point.x, point.y, phase.rawValue, tid, globalTime])
        }
    }
    
    public func startRecord(){
        InputController.root()?.showToast(message: "Record started", seconds: 0.5)
        Toucher.reset()
        recordingButton = []
        isRecording = true
        globalTime = 0
    }
    
    public func stopRecord(){
        InputController.root()?.showToast(message: "Record stopped", seconds: 0.5)
        isRecording = false
        UserDefaults.standard.set(recordingButton, forKey: "playcover.record")
    }

    
    var isPlayback = false
    public func playback(){
        dispatches = [:]
        if let z = UserDefaults.standard.array(forKey: "playcover.record"){
            for case let n as Array<Any> in z{
                dispatches[n[4] as! Int] = [CGPoint(x: n[0] as! CGFloat,y: n[1] as! CGFloat) ,UITouch.Phase.init(rawValue: n[2] as! Int),1]
            }
        } else {
            for n  in recordingButton{
                dispatches[n[4] as! Int] = [CGPoint(x: n[0] as! CGFloat,y: n[1] as! CGFloat) ,UITouch.Phase.init(rawValue: n[2] as! Int),1]
            }
        }
        Toucher.reset()
        globalTime = 0
        endTime = dispatches.keys.max()! + 1
        isPlayback = true
        }

    private var endTime = 0
    @objc func dispatchTouch(){
        if(globalTime > endTime){
            isPlayback = false
            globalTime = 0
            endTime = 0
        }
        if let p = dispatches[globalTime]{
            Toucher.touch(point: p[0] as! CGPoint, phase:  p[1] as! UITouch.Phase, tid: 1)
        }
        
    }
}

