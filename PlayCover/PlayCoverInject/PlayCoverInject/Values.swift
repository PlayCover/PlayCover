//
//  Values.swift
//  PlayCoverInject
//

import Foundation
import UIKit

class Values {
    static var screenWidth : CGFloat {
        windowWidth() * 1.3
    }
    static var screenHeight : CGFloat {
        windowHeight() * 1.3
    }
}

func windowHeight() -> CGFloat {
    return UIScreen.main.bounds.size.height
}

func windowWidth() -> CGFloat {
    return UIScreen.main.bounds.size.width
}
