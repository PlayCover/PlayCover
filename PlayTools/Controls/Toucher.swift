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
        }
    }
    
}
