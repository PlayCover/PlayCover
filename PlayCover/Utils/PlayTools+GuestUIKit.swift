//
//  PlayTools+GuestUIKit.swift
//  PlayCover
//

import Foundation
import InjectionLibrary

extension PlayTools {
    /// Dylib that keeps UIKit scene updates on the main queue for every 64-bit guest.
    static let guestUIKitName = "GuestUIKit.dylib"

    static var installedGuestUIKit: URL {
        frameworksURL
            .appendingPathComponent("PlayTools.framework")
            .appendingPathComponent(guestUIKitName)
    }

    static func bundledGuestUIKit() -> URL? {
        let name = guestUIKitName
        let candidates = [
            Bundle.main.bundleURL
                .appendingPathComponent("Contents")
                .appendingPathComponent("Resources")
                .appendingPathComponent(name),
            Bundle.main.bundleURL
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Contents")
                .appendingPathComponent("Resources")
                .appendingPathComponent(name)
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func installGuestUIKitOnSystem() throws {
        guard let source = bundledGuestUIKit() else { return }
        if FileManager.default.fileExists(atPath: installedGuestUIKit.path) {
            try FileManager.default.removeItem(at: installedGuestUIKit)
        }
        try FileManager.default.copyItem(at: source, to: installedGuestUIKit)
    }

    static func ensureGuestUIKit(in executable: URL, loadPath: String? = nil) throws -> Bool {
        if (try? Macho.installRoute(at: executable)) == .legacy32 {
            return false
        }
        let path = loadPath ?? installedGuestUIKit.path
        if loadPath == nil {
            try installGuestUIKitOnSystem()
        }
        if try machoLoadsGuestUIKit(executable, path: path) {
            return false
        }
        var injected = false
        Inject.injectMachO(machoPath: executable.path,
                           cmdType: .loadDylib,
                           backup: false,
                           injectPath: path,
                           finishHandle: { injected = $0 })
        return injected
    }

    private static func machoLoadsGuestUIKit(_ url: URL, path: String) throws -> Bool {
        var binary = try Data(contentsOf: url)
        try Macho.stripBinary(&binary)
        var found = false
        try _ = Macho.iterateLoadCommands(binary: binary) { offset, shouldSwap in
            let loadCommand = binary.extract(load_command.self, offset: offset,
                                             swap: shouldSwap ? swap_load_command : nil)
            guard loadCommand.cmd == UInt32(LC_LOAD_DYLIB) else { return false }
            let dylibCommand = binary.extract(dylib_command.self, offset: offset,
                                              swap: shouldSwap ? swap_dylib_command : nil)
            let dylibName = String(data: binary,
                                   offset: offset,
                                   commandSize: Int(dylibCommand.cmdsize),
                                   loadCommandString: dylibCommand.dylib.name)
            if dylibName == path || dylibName.hasSuffix("/\(guestUIKitName)") {
                found = true
                return true
            }
            return false
        }
        return found
    }
}
