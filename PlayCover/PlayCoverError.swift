import AudioToolbox
import Foundation
import SwiftUI

enum PlayCoverError: Error {
    case infoPlistNotFound
    case waitInstallation
    case waitDownload
    case appEncrypted
    case appCorrupted
    case appProhibited
    case appProhibitedTiktok
    case noGenshinAccount
}

extension PlayCoverError: LocalizedError {
    public var errorDescription: String? {
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
        case .appProhibitedTiktok:
            return NSLocalizedString("error.appProhibitedTiktok", comment: "")
        case .noGenshinAccount:
            return NSLocalizedString("error.noGenshinAccount", comment: "")
        }
    }
}
