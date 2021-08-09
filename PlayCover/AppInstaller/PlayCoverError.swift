//
//  PlayCoverError.swift
//  PlayCover
//

import Foundation

enum PlayCoverError: Error {
    case cantCreateTemp
    case ipaCorrupted
    case cantDecryptIpa
    case infoPlistNotFound
    case sipDisabled
}
