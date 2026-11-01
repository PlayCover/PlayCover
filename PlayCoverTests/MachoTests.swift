//
//  MachoTests.swift
//  PlayCoverTests
//

import Foundation
import MachO
import Testing
@testable import PlayCover

struct MachoTests {
    private static let playToolsBinary = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "ThirdParty/PlayTools/PlayTools.xcframework/ios-arm64/PlayTools.framework/PlayTools")

    @Test func stripsFatBinaryToItsArm64Slice() throws {
        let original = try Data(contentsOf: URL(filePath: "/bin/ls"))
        #expect(original.extract(UInt32.self) == FAT_CIGAM)

        var binary = original
        try Macho.stripBinary(&binary)

        let header = binary.extract(mach_header_64.self)
        #expect(header.magic == MH_MAGIC_64)
        #expect(header.cputype == CPU_TYPE_ARM64)
        #expect(binary.count < original.count)
    }

    @Test func leavesThinBinaryUntouched() throws {
        let original = try Data(contentsOf: Self.playToolsBinary)

        var binary = original
        try Macho.stripBinary(&binary)

        #expect(binary == original)
    }

    @Test func convertsIOSBinaryToMacCatalyst() throws {
        let url = try temporaryFile(contents: try Data(contentsOf: Self.playToolsBinary))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(try Macho.isMachoValidArch(url) == false)

        try Macho.convertMacho(url)

        #expect(try Macho.isMachoValidArch(url))
        #expect(try Macho.isMachoEncrypted(atURL: url) == false)
    }

    @Test func readsLoadCommandsOfByteSwappedBinary() throws {
        let catalyst = try temporaryFile(contents: Self.bigEndianBinary(platform: UInt32(PLATFORM_MACCATALYST),
                                                                         cryptid: 1))
        let ios = try temporaryFile(contents: Self.bigEndianBinary(platform: UInt32(PLATFORM_IOS), cryptid: 0))
        defer {
            try? FileManager.default.removeItem(at: catalyst)
            try? FileManager.default.removeItem(at: ios)
        }

        #expect(try Macho.isMachoValidArch(catalyst))
        #expect(try Macho.isMachoEncrypted(atURL: catalyst))
        #expect(try Macho.isMachoValidArch(ios) == false)
        #expect(try Macho.isMachoEncrypted(atURL: ios) == false)
    }

    @Test func rejectsTruncatedBinary() throws {
        let truncated = Self.bigEndianBinary(platform: UInt32(PLATFORM_IOS), cryptid: 0)
            .prefix(MemoryLayout<mach_header_64>.size + 8)
        let url = try temporaryFile(contents: Data(truncated))
        defer { try? FileManager.default.removeItem(at: url) }

        #expect(throws: PlayCoverError.self) {
            try Macho.isMachoValidArch(url)
        }
    }

    @Test func byteSwappingSwapsEveryFieldAndIsReversible() {
        let command = dylib_command(cmd: UInt32(LC_LOAD_DYLIB), cmdsize: 56,
                                    dylib: MachO.dylib(name: lc_str(offset: 24), timestamp: 2,
                                                       current_version: 0x10000, compatibility_version: 0x20000))
        let swappedCommand = command.byteSwapped
        #expect(swappedCommand.cmd == UInt32(LC_LOAD_DYLIB).byteSwapped)
        #expect(swappedCommand.dylib.name.offset == UInt32(24).byteSwapped)
        #expect(swappedCommand.dylib.compatibility_version == UInt32(0x20000).byteSwapped)
        #expect(bytes(of: swappedCommand.byteSwapped) == bytes(of: command))

        let arch = fat_arch(cputype: CPU_TYPE_ARM64, cpusubtype: 2, offset: 16384, size: 1000, align: 14)
        #expect(arch.byteSwapped.cputype == CPU_TYPE_ARM64.byteSwapped)
        #expect(arch.byteSwapped.offset == UInt32(16384).byteSwapped)
        #expect(bytes(of: arch.byteSwapped.byteSwapped) == bytes(of: arch))

        let header = fat_header(magic: FAT_MAGIC, nfat_arch: 2)
        #expect(header.byteSwapped.magic == FAT_CIGAM)
        #expect(header.byteSwapped.nfat_arch == UInt32(2).byteSwapped)
    }

    /// A minimal slim Mach-O stored in the opposite byte order, with a build version and an encryption command.
    private static func bigEndianBinary(platform: UInt32, cryptid: UInt32) -> Data {
        let version = build_version_command(cmd: UInt32(LC_BUILD_VERSION),
                                            cmdsize: UInt32(MemoryLayout<build_version_command>.size),
                                            platform: platform, minos: 0x000b0000, sdk: 0x000e0000, ntools: 0)
        let encryption = encryption_info_command_64(cmd: UInt32(LC_ENCRYPTION_INFO_64),
                                                    cmdsize: UInt32(MemoryLayout<encryption_info_command_64>.size),
                                                    cryptoff: 0, cryptsize: 0, cryptid: cryptid, pad: 0)
        let header = mach_header_64(magic: MH_MAGIC_64, cputype: CPU_TYPE_ARM64, cpusubtype: 0,
                                    filetype: UInt32(MH_EXECUTE), ncmds: 2,
                                    sizeofcmds: version.cmdsize + encryption.cmdsize, flags: 0, reserved: 0)
        var data = bytes(of: header.byteSwapped)
        data.append(bytes(of: version.byteSwapped))
        data.append(bytes(of: encryption.byteSwapped))
        // Load commands must end before the end of the file.
        data.append(Data(count: 64))
        return data
    }
}

private func bytes<T>(of value: T) -> Data {
    withUnsafeBytes(of: value) { Data($0) }
}

private func temporaryFile(contents: Data) throws -> URL {
    let url = FileManager.default.temporaryDirectory.appending(path: "MachoTests-\(UUID().uuidString)")
    try contents.write(to: url)
    return url
}
