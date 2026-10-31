//
//  PlayToolsPluginSync.swift
//  PlayCover
//

import CryptoKit
import Foundation

extension PlayTools {
    /// True when the app's PlayTools plugins or strings differ from the copies shipped
    /// inside PlayCover. Re-signing a plugin changes its code signature but not the bytes
    /// before that signature, so those bytes are what get compared.
    static func pluginsNeedUpdate(in payload: URL) -> Bool {
        do {
            return try !pluginsMatch(payload)
        } catch {
            return true
        }
    }

    private static func pluginsMatch(_ payload: URL) throws -> Bool {
        for pair in try pluginFilePairs(payload: payload) {
            guard FileManager.default.fileExists(atPath: pair.target.path) else { return false }
            if try contentDigest(pair.source) != contentDigest(pair.target) {
                return false
            }
        }
        return true
    }

    private static func pluginFilePairs(payload: URL) throws -> [(source: URL, target: URL)] {
        var strings: [String: URL] = [:]
        try collectPlaytoolsStrings(from: bundledPlayToolsFramework, into: &strings)
        let resources = bundledPlayToolsFramework
            .appendingPathComponent("Versions")
            .appendingPathComponent("A")
            .appendingPathComponent("Resources")
        if FileManager.default.fileExists(atPath: resources.path) {
            try collectPlaytoolsStrings(from: resources, into: &strings)
        }

        var pairs = strings.map { relative, source in
            (source: source, target: appendRelative(relative, to: payload))
        }

        let pluginsSource = bundledPlayToolsFramework.appendingPathComponent("PlugIns")
        let bundleNames = try FileManager.default.contentsOfDirectory(atPath: pluginsSource.path)
        for name in bundleNames where name.hasSuffix(".bundle") {
            let sourceRoot = pluginsSource.appendingPathComponent(name)
            let targetRoot = payload.appendingPathComponent("PlugIns").appendingPathComponent(name)
            for relative in try filesUnder(sourceRoot) {
                pairs.append((
                    source: appendRelative(relative, to: sourceRoot),
                    target: appendRelative(relative, to: targetRoot)
                ))
            }
        }
        return pairs
    }

    private static func collectPlaytoolsStrings(from root: URL, into strings: inout [String: URL]) throws {
        let directories = try FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil)
        for directory in directories where directory.pathExtension == "lproj" {
            let file = directory
                .appendingPathComponent("Playtools")
                .appendingPathExtension("strings")
            let relative = "\(directory.lastPathComponent)/Playtools.strings"
            strings[relative] = file
        }
    }

    private static func filesUnder(_ root: URL) throws -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]) else {
            return []
        }
        var relativePaths: [String] = []
        let rootPath = root.path
        for case let fileURL as URL in enumerator {
            if fileURL.lastPathComponent == "_CodeSignature" {
                (enumerator as? FileManager.DirectoryEnumerator)?.skipDescendants()
                continue
            }
            let values = try fileURL.resourceValues(
                forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .isDirectoryKey])
            if values.isSymbolicLink == true {
                (enumerator as? FileManager.DirectoryEnumerator)?.skipDescendants()
            } else if values.isDirectory == true {
                continue
            } else if values.isRegularFile != true {
                continue
            }
            let full = fileURL.path
            guard full.hasPrefix(rootPath + "/") else { continue }
            relativePaths.append(String(full.dropFirst(rootPath.count + 1)))
        }
        return relativePaths.sorted()
    }

    private static func appendRelative(_ relative: String, to base: URL) -> URL {
        relative.split(separator: "/").reduce(base) { partial, part in
            partial.appendingPathComponent(String(part))
        }
    }

    private static func contentDigest(_ url: URL) throws -> SHA256Digest {
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        if values.isSymbolicLink == true {
            let destination = try FileManager.default.destinationOfSymbolicLink(atPath: url.path)
            return SHA256.hash(data: Data(destination.utf8))
        }
        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        if let offset = machoSignatureOffset(data), offset > 0 {
            return SHA256.hash(data: data.prefix(offset))
        }
        return SHA256.hash(data: data)
    }

    /// Byte offset of an embedded code signature, so two ad-hoc signatures of the same
    /// binary still compare equal.
    private static func machoSignatureOffset(_ data: Data) -> Int? {
        guard data.count >= MemoryLayout<mach_header_64>.size else { return nil }
        let magic = data.extract(UInt32.self)
        guard magic == MH_MAGIC_64 || magic == MH_CIGAM_64 else { return nil }
        var dataoff: UInt32?
        do {
            _ = try Macho.iterateLoadCommands(binary: data) { offset, shouldSwap in
                let command = data.extract(load_command.self, offset: offset,
                                            swap: shouldSwap ? swap_load_command : nil)
                guard command.cmd == UInt32(LC_CODE_SIGNATURE) else { return false }
                let raw = data.extract(UInt32.self, offset: offset + 8)
                dataoff = shouldSwap ? raw.byteSwapped : raw
                return true
            }
        } catch {
            return nil
        }
        guard let dataoff, dataoff > 0, Int(dataoff) <= data.count else { return nil }
        return Int(dataoff)
    }
}
