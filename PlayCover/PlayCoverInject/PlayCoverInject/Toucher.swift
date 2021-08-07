//
//  Toucher.swift
//  PlayCoverInject
//
//  Created by Alice on 30.06.2021.
//

import Foundation
import UIKit

class Toucher{
    static func touch(point : CGPoint, phase : UITouch.Phase, tid : Int){
        DispatchQueue.main.async {
            Recorder.shared.recordButton(point: point, phase: phase, tid: tid)
            PTFakeMetaTouch.fakeTouchId(tid, at: point, with: phase)
        }
    }
    static func reset(){
        PTFakeMetaTouch.fakeTouchId(1, at: CGPoint(x: 0,y: 0), with: UITouch.Phase.ended)
    }
}
