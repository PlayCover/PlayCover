//
//  PlayApp+GuestRuntime.swift
//  PlayCover
//

import Foundation

extension PlayApp {
    /// Refuse a 32-bit guest, then make sure GuestUIKit is loaded before launch.
    func prepareGuestRuntime() throws {
        if (try? Macho.installRoute(at: executable)) == .legacy32 {
            throw PlayCoverError.legacy32Unavailable
        }
        if try PlayTools.ensureGuestUIKit(in: executable) {
            try Shell.signApp(executable)
        }
    }
}
