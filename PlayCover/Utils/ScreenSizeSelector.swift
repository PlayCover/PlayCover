//
//  getScreenSizeSelector.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 18/08/22.
//

import Foundation

func getScreenSizeSelector(_ height: Float) -> Int? {
    switch height {
    case 720:
        return 0
    case 1080.0:
        return 1
    case 1440.0:
        return 2
    case 2160:
        return 3
    case 1280: // Vertical screen
        return 4
    case 844: // Vertical screen
        return 5
    case 1000:
        return 6
    default:
        return nil
    }
}
