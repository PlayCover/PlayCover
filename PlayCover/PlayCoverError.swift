import AudioToolbox
import Foundation
import SwiftUI

nonisolated enum PlayCoverError: Error, Sendable {
    case infoPlistNotFound
    case waitInstallation
    case waitDownload
    case appEncrypted
    case appCorrupted
    case appProhibited
    case appMaliciousProhibited
    case failedToStripBinary
    case invalidUserDylib
    case invalidSignature
    case launchTimedOut
}

extension PlayCoverError: LocalizedError {
    nonisolated public var errorDescription: String? {
        switch self {
        case .infoPlistNotFound:
            return NSLocalizedString("error.corruptedIPA", comment: "")
        case .waitInstallation:
            return NSLocalizedString("error.waitInstallation", comment: "")
        case .waitDownload:
            return NSLocalizedString("error.waitDownload", comment: "")
        case .appEncrypted:
            return NSLocalizedString("error.appEncrypted", comment: "")
        case .appCorrupted:
            return NSLocalizedString("error.appCorrupted", comment: "")
        case .appProhibited:
            return NSLocalizedString("error.appProhibited", comment: "")
        case .appMaliciousProhibited:
            return NSLocalizedString("error.appMaliciousProhibited", comment: "")
        case .failedToStripBinary:
            return NSLocalizedString("error.failedToStripBinary", comment: "")
        case .invalidUserDylib:
            return NSLocalizedString("error.invalidUserDylib", comment: "")
        case .invalidSignature:
            return NSLocalizedString("error.invalidSignature", comment: "")
        case .launchTimedOut:
            return NSLocalizedString("error.launchTimedOut", comment: "")
        }
    }
}
