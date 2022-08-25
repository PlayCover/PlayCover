//
//  GlobalConstants.swift
//  PlayCover
//
//  Created by Nikita Semenov on 25.08.2022.
//

import Foundation

struct Constants {
    static let appViewSize: CGFloat = 150

    static var mainWindowHeight: CGFloat = 650

    static var mainWindowWidth: CGFloat {
        // 4 - max apps in the row
        // 27 - spacing
        (appViewSize + 27) * 4
    }
}
