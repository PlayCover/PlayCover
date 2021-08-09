//
//  PlayCoverError.swift
//  PlayCover
//
//  Created by siri on 09.08.2021.
//

import Foundation

enum PlayCoverError: Error {
    case cantCreateTemp
    case ipaCorrupted
    case cantDecryptIpa
    case infoPlistNotFound
    case sipDisabled
}
