//
//  PlayMice.swift
//  PlayTools
//

import Foundation

import GameController
import CoreGraphics

typealias ResponseBlock = @convention(block) (_ event: Any) -> Any?

typealias ResponseBlockBool = @convention(block) (_ event: Any) -> Bool

@objc final public class PlayMice : NSObject {
    
    @objc public static let shared = PlayMice()
    
    private var camera : CameraControl? = nil
    
    private static var isInit = false
    
    private var acceptMouseEvents = !PlaySettings.shared.gamingMode
    
    public override init() {
        super.init()
        if !PlayMice.isInit {
            setupMouseButton(_up: 2, _down: 4)
            setupMouseButton(_up: 8, _down: 16)
            setupMouseButton(_up: 33554432, _down: 67108864)
            PlayMice.isInit = true
        }
    }
    
    public var cursorPos : CGPoint {
        var point = CGPoint(x: 0,y: 0)
        if #available(macOS 11, *) {
            point = Dynamic(screen.nsWindow).mouseLocationOutsideOfEventStream.asCGPoint!
        }
        if let rect = (Dynamic(screen.nsWindow).frame.asCGRect){
            point.x = (point.x / rect.width) * screen.screenRect.width
            point.y = screen.screenRect.height - ((point.y / rect.height) * screen.screenRect.height)
        }
        
        return point
    }
    
    public func setup(_ key : Array<CGFloat> ){
        camera = CameraControl(centerX: key[0].absoluteX, centerY: key[1].absoluteY)
        for m in GCMouse.mice(){
            m.mouseInput?.mouseMovedHandler = {
                (mouse, dX, dY) in
                if !mode.visible{
                    self.camera?.updated(CGFloat(dX), CGFloat(dY))
                }
            }
        }
    }
    
    public func stop() {
        for m in GCMouse.mice(){
            m.mouseInput?.mouseMovedHandler = nil
        }
        camera?.stop()
        camera = nil
        mouseActions = [:]
    }
    
    func setMiceButtons(_ keyId : Int, action : ButtonAction) -> Bool {
        if  (-3 ... -1).contains(keyId){
            setMiceButton(keyId, action: action)
            return true
        }
        return false
    }
    
    var mouseActions : [Int:ButtonAction] = [:]
    
    private func setupMouseButton(_up : Int, _down : Int){
        Dynamic.NSEvent.addLocalMonitorForEventsMatchingMask(_up, handler: { event in
            if self.mouseActions[_up] == nil {
                          MacroController.shared.recordEvent(point: self.cursorPos, phase: UITouch.Phase.began, tid: 1)
                      }
            if !mode.visible || self.acceptMouseEvents {
                self.mouseActions[_up]?.update(pressed: true)
                if self.acceptMouseEvents {
                    return event
                }
                return nil
            }
            return event
        } as ResponseBlock)
        Dynamic.NSEvent.addLocalMonitorForEventsMatchingMask(_down, handler: { event in
            if self.mouseActions[_up] == nil {
                          MacroController.shared.recordEvent(point: self.cursorPos, phase: UITouch.Phase.began, tid: 1)
                      }
            if !mode.visible || self.acceptMouseEvents {
                self.mouseActions[_up]?.update(pressed: false)
                if self.acceptMouseEvents {
                    return event
                }
                return nil
            }
            return event
        } as ResponseBlock)
    }
    
    private func setMiceButton(_ keyId : Int, action : ButtonAction) {
        switch(keyId){
        case -1: mouseActions[2] = action;
        case -2: mouseActions[8] = action;
        case -3: mouseActions[33554432] = action;
        default:
            mouseActions[2] = action;
        }
        
    }
}

final class CameraControl {

    var center : CGPoint = CGPoint.zero
    var location : CGPoint = CGPoint.zero

    init(centerX : CGFloat = screen.width / 2, centerY : CGFloat = screen.height / 2) {
        self.center = CGPoint(x: centerX, y: centerY)
    }

    var isMoving = false

    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }


    var counter = 0

    @objc func updated(_ dx: CGFloat, _ dy: CGFloat){
        if mode.visible {
            return
        }
        counter+=1
        
        if !isMoving{
            isMoving = true
            location = center
            Toucher.touchcam(point: self.center, phase: UITouch.Phase.began, tid: 1)
        }
        self.location.x += dx * CGFloat(PlaySettings.shared.sensivity)
        self.location.y -= dy * CGFloat(PlaySettings.shared.sensivity)
        Toucher.touchcam(point: self.location, phase: UITouch.Phase.moved, tid: 1)
        let previous = counter

        delay(0.016){
                if self.isMoving && previous == self.counter {
                    Toucher.touchcam(point: self.center, phase: UITouch.Phase.ended, tid: 1)
                    self.isMoving = false
                }
         }

    }

    func stop() {
        counter = 0
        isMoving = false
        Toucher.touchcam(point: center, phase: UITouch.Phase.ended, tid: 1)
        location = center
    }
}


