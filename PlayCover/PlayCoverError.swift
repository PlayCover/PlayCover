import SwiftUI
import AudioToolbox

enum PlayCoverError: Error {
    case infoPlistNotFound
    case waitInstallation
    case playcoverReinstall
    case appEncrypted
    case appCorrupted
    case appProhibited
    case noGenshinAccount
}

extension PlayCoverError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .infoPlistNotFound:
            return NSLocalizedString("This IPA is corrupted. It doesn't contain an Info.plist file.", comment: "")
        case .waitInstallation:
            return NSLocalizedString("Please wait for the current installation to finish!", comment: "")
        case .playcoverReinstall:
            return NSLocalizedString("Please reinstall the PlayCover app", comment: "")
        case .appEncrypted:
            return NSLocalizedString("This app is encrypted! Please use a decrypted IPA from AppDb or download " +
                                     "one from the internal store. iMazing IPA are not currently supported!",
                                     comment: "")
        case .appCorrupted:
            return NSLocalizedString("Something went wrong with this IPA. Please try to use another IPA file.",
                                     comment: "")
        case .appProhibited:
            return NSLocalizedString("You may receive a ban! There have been reports of" +
                                     " bans when playing this game using PlayCover.", comment: "")
        case .noGenshinAccount:
            return NSLocalizedString("We couldn't find a Genshin account! Are you signed into an account in-app?",
                                     comment: "")
    }
    }
}
