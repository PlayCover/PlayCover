//
//  getScreenSizeSelector.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 18/08/22.
//

import Foundation

func getScreenSizeSelector(_ height: Float) -> Int? {
    switch height {
    case 1080.0:
        return 0
    case 1440.0:
        return 1
    case 2160:
        return 2
    case 1280: // Vertical screen
        return 3
    default:
        return nil
    }
}
