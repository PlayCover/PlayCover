//
//  SetScreenSize.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 19/08/22.
//

import Foundation

func setScreenSize(tag: Int, settings: AppSettings) {
    switch tag {
    case 0:
        settings.gameWindowSizeHeight = 720
        settings.gameWindowSizeWidth = 1280
    case 1:
        settings.gameWindowSizeHeight = 1080
        settings.gameWindowSizeWidth = (1080 * 1.77777777777778) + 100
    case 2:
        settings.gameWindowSizeHeight = 1440
        settings.gameWindowSizeWidth = (1400 * 1.77777777777778) + 100
    case 3:
        settings.gameWindowSizeHeight = 2160
        settings.gameWindowSizeWidth = (2160 * 1.77777777777778) + 100
    case 4:
        settings.gameWindowSizeHeight = 1280
        settings.gameWindowSizeWidth = 720
    case 5:
        settings.gameWindowSizeHeight = 844
        settings.gameWindowSizeWidth = 390
    case 6:
        settings.gameWindowSizeHeight = 1000
        settings.gameWindowSizeWidth = 1600
    default:
        return
    }
}
