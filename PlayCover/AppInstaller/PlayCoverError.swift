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
    case appInstalledNotProperly
}

extension PlayCoverError: LocalizedError {
    public var errorDescription: String? {
        
        switch self {
        case .cantDecryptIpa:
            let msg = NSLocalizedString("This .IPA can't be decrypted on this Mac. Download this .ipa from AppDb.to", comment: "")
            evm.error = msg
            return msg
        case .infoPlistNotFound:
            let msg = NSLocalizedString("This .IPA is courrupted. It doesn't contains Info.plist.", comment: "")
            evm.error = msg
            return msg
        case .sipDisabled:
            let msg = NSLocalizedString("It it impossible to decrypt .IPA with SIP disabled. Please, enable it.", comment: "")
            evm.error = msg
            return msg
        case .appInstalledNotProperly:
            let msg = NSLocalizedString("Please reinstall PlayCoverApp", comment: "")
            evm.error = msg
            return msg
        case .cantCreateTemp:
            let msg = NSLocalizedString("Make sure you don't disallowed PlayCover to access files in Settings - Secuirity & Privacy", comment: "")
            evm.error = msg
            return msg
        case .ipaCorrupted:
            let msg = NSLocalizedString("This .IPA is courrupted.Try to use another .ipa", comment: "")
            evm.error = msg
            return msg
        }
    }
}

