
import Foundation
import SwiftUI
import AudioToolbox

enum PlayCoverError: Error {
    case infoPlistNotFound
    case waitInstallation
    case playcoverReinstall
    case appEncrypted
    case appCorrupted
    case appProhibited
}

extension PlayCoverError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .infoPlistNotFound:
            return NSLocalizedString("This .IPA is courrupted. It doesn't contains Info.plist.", comment: "")
        case .waitInstallation:
            return NSLocalizedString("Please, wait for the current install to finish!", comment: "")
        case .playcoverReinstall:
            return NSLocalizedString("Please, reinstall the PlayCover app", comment: "")
        case .appEncrypted:
            return NSLocalizedString("App is encrypted! Please, use decrypted .ipa from AppDb or download one from the internal store. iMazing .ipa are not currently supported!", comment: "")
        case .appCorrupted:
            return NSLocalizedString("Something went wrong with this .ipa. Please try to use another .ipa file.", comment: "")
        case .appProhibited:
            return NSLocalizedString("You'll receive a ban on this PlayCover version! Call of Duty is supported on 0.9.2-0.9.4. PUBG requires a higher PlayCover version. Free Fire's status is not confirmed. There is one message of ban.", comment: "")
    }
    }
}

