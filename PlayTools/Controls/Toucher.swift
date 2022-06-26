//
//  Toucher.swift
//  PlayCoverInject
//

import Foundation
import UIKit

class Toucher {
    
    static func touchcam(point : CGPoint, phase : UITouch.Phase, tid : Int){
        DispatchQueue.main.async {
            PTFakeMetaTouch.fakeTouchId(tid, at: point, with: phase)
            MacroController.shared.recordEvent(point: point, phase: phase, tid: tid)
        }
    }
    
    static func reset(){
        var c = 0
        for id in 1...99 {
            c += 1
            DispatchQueue.main.async {
                PTFakeMetaTouch.fakeTouchId(id, at: CGPoint(x: 0,y: 0), with: UITouch.Phase.ended)
            }
        }
    }
    
}
