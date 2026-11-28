// swiftlint:disable file_length
//
//  Macho.swift
//  PlayCover
//

import Foundation

// swiftlint:disable:next type_body_length
class Macho {
    private struct FatArchitecture {
        let cpu: cpu_type_t
        let subtype: cpu_subtype_t
        let offset: UInt64
        let size: UInt64
    }

    private struct FatTable {
        static let headerSize = MemoryLayout<fat_header>.size
        let count: Int
        let uses64BitOffsets: Bool
        let shouldSwap: Bool

        var entrySize: Int {
            uses64BitOffsets ? MemoryLayout<fat_arch_64>.size : MemoryLayout<fat_arch>.size
        }

        var byteCount: Int { count * entrySize }

        init?(headerData: Data, fileSize: UInt64) throws {
            guard headerData.count >= Self.headerSize else { throw PlayCoverError.appCorrupted }
            var header = headerData.extract(fat_header.self)
            let magic = header.magic
            uses64BitOffsets = magic == FAT_MAGIC_64 || magic == FAT_CIGAM_64
            guard uses64BitOffsets || magic == FAT_MAGIC || magic == FAT_CIGAM else { return nil }
            shouldSwap = magic == FAT_CIGAM || magic == FAT_CIGAM_64
            if shouldSwap { swap_fat_header(&header, NXHostByteOrder()) }
            count = Int(header.nfat_arch)
            guard fileSize >= UInt64(Self.headerSize), count > 0,
                  UInt64(count) <= (fileSize - UInt64(Self.headerSize)) / UInt64(entrySize) else {
                throw PlayCoverError.appCorrupted
            }
        }

        func arm64Range(in table: Data, fileSize: UInt64) throws -> Range<UInt64> {
            guard table.count == byteCount else { throw PlayCoverError.appCorrupted }
            let firstPossibleOffset = UInt64(Self.headerSize + byteCount)
            var fallback: Range<UInt64>?
            for index in 0..<count {
                let entry = architecture(in: table, offset: index * entrySize)
                guard entry.cpu == CPU_TYPE_ARM64 else { continue }
                guard entry.offset >= firstPossibleOffset, entry.offset <= fileSize,
                      entry.size >= UInt64(MemoryLayout<mach_header_64>.size),
                      entry.size <= fileSize - entry.offset else {
                    throw PlayCoverError.appCorrupted
                }
                let range = entry.offset..<(entry.offset + entry.size)
                let subtype = UInt32(bitPattern: entry.subtype) & ~CPU_SUBTYPE_MASK
                if subtype == UInt32(CPU_SUBTYPE_ARM64_ALL) { return range }
                if fallback == nil { fallback = range }
            }
            if let fallback { return fallback }
            throw PlayCoverError.failedToStripBinary
        }

        private func architecture(in table: Data, offset: Int) -> FatArchitecture {
            if uses64BitOffsets {
                var entry = table.extract(fat_arch_64.self, offset: offset)
                if shouldSwap { swap_fat_arch_64(&entry, 1, NXHostByteOrder()) }
                return FatArchitecture(
                    cpu: entry.cputype, subtype: entry.cpusubtype, offset: entry.offset, size: entry.size
                )
            }
            var entry = table.extract(fat_arch.self, offset: offset)
            if shouldSwap { swap_fat_arch(&entry, 1, NXHostByteOrder()) }
            return FatArchitecture(
                cpu: entry.cputype, subtype: entry.cpusubtype,
                offset: UInt64(entry.offset), size: UInt64(entry.size)
            )
        }
    }

    static func stripBinary(_ binary: inout Data) throws {
        let fileSize = UInt64(binary.count)
        guard let table = try FatTable(headerData: binary, fileSize: fileSize) else { return }
        let start = FatTable.headerSize
        let entries = binary.subdata(in: start..<(start + table.byteCount))
        let range = try table.arm64Range(in: entries, fileSize: fileSize)
        binary = binary.subdata(in: Int(range.lowerBound)..<Int(range.upperBound))
    }

    /// Reads only the FAT header and architecture table for callers inspecting load commands.
    static func selectedArm64Slice(in handle: FileHandle) throws -> Range<UInt64> {
        let fileSize = try handle.seekToEnd()
        try handle.seek(toOffset: 0)
        guard let header = try handle.read(upToCount: FatTable.headerSize) else {
            throw PlayCoverError.appCorrupted
        }
        guard let table = try FatTable(headerData: header, fileSize: fileSize) else { return 0..<fileSize }
        guard table.byteCount <= 1024 * 1024, let entries = try handle.read(upToCount: table.byteCount) else {
            throw PlayCoverError.appCorrupted
        }
        return try table.arm64Range(in: entries, fileSize: fileSize)
    }

    static func convertMacho(_ macho: URL, in app: URL? = nil) throws {
        print("Converting MachO at \(macho.path)")

        var binary = try Data(contentsOf: macho)

        print("Stripping MachO...")
        try stripBinary(&binary)
        if try !isCatalyst(binary) {
            print("Replacing version command...")
            try replaceVersionCommand(&binary)
        }
        _ = try resolveSystemLibraryAliases(&binary, at: macho, in: app)
        if try stripRestrictSegment(&binary) {
            print("Neutralized __RESTRICT segment in MachO")
        }

        print("Writing revised MachO...")
        try binary.write(to: macho, options: .atomic)
        try macho.setBinaryPosixPermissions(0o755)
    }

    static let libraryRepairSchemaVersion = 2

    private static let iOSSupportSwiftDirectory = "/System/iOSSupport/usr/lib/swift"
    private static let macOSSwiftDirectory = "/usr/lib/swift"

    // Keep the Catalyst overlay for framework libraries that were previously
    // explicitly mapped and can also have a macOS overlay of the same name.
    private static let catalystFrameworkOverlays: Set<String> = [
        "libswiftUIKit.dylib", "libswiftARKit.dylib", "libswiftMapKit.dylib",
        "libswiftSceneKit.dylib", "libswiftPhotosUI.dylib", "libswiftCoreNFC.dylib",
        "libswiftPencilKit.dylib", "libswiftWebKit.dylib", "libswiftHomeKit.dylib",
        "libswiftPassKit.dylib"
    ]

    private typealias SharedCacheContainsPath = @convention(c) (UnsafePointer<CChar>) -> Bool

    private static let sharedCacheContainsPath: SharedCacheContainsPath? = {
        guard let handle = dlopen(nil, RTLD_LAZY) else { return nil }
        defer { dlclose(handle) }
        guard let symbol = dlsym(handle, "_dyld_shared_cache_contains_path") else { return nil }
        return unsafeBitCast(symbol, to: SharedCacheContainsPath.self)
    }()

    private static func systemLibraryExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
            || path.withCString { sharedCacheContainsPath?($0) == true }
    }

    private static let catalystSystemRoot = "/System/iOSSupport"

    private struct StartupLinks {
        let required: [String]
        let optional: [String]
        let runPaths: [String]
    }

    private static func startupLinks(at image: URL) throws -> StartupLinks {
        // Startup graph traversal only needs load commands, not __TEXT/__LINKEDIT.
        // In particular, do not copy a whole arm64 slice out of a universal binary.
        let handle = try FileHandle(forReadingFrom: image)
        defer { try? handle.close() }
        let slice = try selectedArm64Slice(in: handle)
        let headerSize = MemoryLayout<mach_header_64>.size
        guard slice.count >= headerSize else { throw PlayCoverError.appCorrupted }
        try handle.seek(toOffset: slice.lowerBound)
        guard let data = try handle.read(upToCount: headerSize), data.count == headerSize else {
            throw PlayCoverError.appCorrupted
        }
        var header = data.extract(mach_header_64.self)
        guard header.magic == MH_MAGIC_64 || header.magic == MH_CIGAM_64 else {
            throw PlayCoverError.appCorrupted
        }
        if header.magic == MH_CIGAM_64 { swap_mach_header_64(&header, NXHostByteOrder()) }
        guard UInt64(header.sizeofcmds) <= slice.upperBound - slice.lowerBound - UInt64(headerSize) else {
            throw PlayCoverError.appCorrupted
        }
        guard let commands = try handle.read(upToCount: Int(header.sizeofcmds)),
              commands.count == Int(header.sizeofcmds) else { throw PlayCoverError.appCorrupted }
        return try startupLinks(in: data + commands)
    }

    private static func startupLinks(in binary: Data) throws -> StartupLinks {
        var required: [String] = []
        var optional: [String] = []
        var runPaths: [String] = []
        _ = try iterateLoadCommands(binary: binary) { offset, shouldSwap in
            let command = binary.extract(load_command.self, offset: offset,
                                         swap: shouldSwap ? swap_load_command : nil)
            let isRunPath = command.cmd == UInt32(LC_RPATH)
            let isWeak = command.cmd == UInt32(LC_LOAD_WEAK_DYLIB)
            guard isRunPath || isWeak || command.cmd == UInt32(LC_LOAD_DYLIB)
                    || command.cmd == UInt32(LC_REEXPORT_DYLIB)
                    || command.cmd == UInt32(LC_LOAD_UPWARD_DYLIB) else { return false }
            let minimumSize = isRunPath ? MemoryLayout<rpath_command>.size : MemoryLayout<dylib_command>.size
            guard Int(command.cmdsize) >= minimumSize else { return false }
            let raw = binary.extract(lc_str.self, offset: offset + MemoryLayout<load_command>.size).offset
            let nameOffset = Int(shouldSwap ? raw.byteSwapped : raw)
            guard nameOffset >= minimumSize, nameOffset < Int(command.cmdsize) else { return false }
            let bytes = binary[(offset + nameOffset)..<(offset + Int(command.cmdsize))]
            guard let terminator = bytes.firstIndex(of: 0),
                  let name = String(bytes: bytes[..<terminator], encoding: .utf8) else { return false }
            if isRunPath {
                runPaths.append(name)
            } else if isWeak {
                optional.append(name)
            } else {
                required.append(name)
            }
            return false
        }
        return StartupLinks(required: required, optional: optional, runPaths: runPaths)
    }

    static func hasCustomLibrarySearch(_ environment: [String: String],
                                       exceptFrameworkPath: String? = nil) -> Bool {
        environment.contains { key, value in
            !value.isEmpty && key.hasPrefix("DYLD_") && (key.hasSuffix("_PATH") || key == "DYLD_IMAGE_SUFFIX")
                && !(key == "DYLD_FRAMEWORK_PATH" && value == exceptFrameworkPath)
        }
    }

    private static func appLibrarySearchDirectories(at image: URL, in app: URL?, binary: Data) -> [URL]? {
        let loaderDirectory = image.deletingLastPathComponent()
        var directories = [loaderDirectory]
        var executable = image
        if let app = app {
            directories.append(app.appendingPathComponent("Frameworks"))
            if let metadata = try? [String: Any].read(app.appendingPathComponent("Info.plist")) {
                if let environment = metadata["LSEnvironment"] as? [String: String],
                   hasCustomLibrarySearch(environment) { return nil }
                if let name = metadata["CFBundleExecutable"] as? String {
                    executable = app.appendingPathComponent(name)
                }
            }
        }
        let executableDirectory = executable.deletingLastPathComponent().path
        func expand(_ paths: [String], loader: String) -> [URL] {
            paths.compactMap { path in
                if path.hasPrefix("@executable_path/") || path == "@executable_path" {
                    return URL(fileURLWithPath: executableDirectory + path.dropFirst("@executable_path".count))
                }
                if path.hasPrefix("@loader_path/") || path == "@loader_path" {
                    return URL(fileURLWithPath: loader + path.dropFirst("@loader_path".count))
                }
                return path.hasPrefix("/") ? URL(fileURLWithPath: path) : nil
            }
        }
        directories += expand((try? startupLinks(in: binary))?.runPaths ?? [], loader: loaderDirectory.path)
        if executable.standardizedFileURL != image.standardizedFileURL {
            directories += expand((try? startupLinks(at: executable))?.runPaths ?? [], loader: executableDirectory)
        }
        return directories
    }

    private static func hostedLibraryInstallName(for suffix: String) -> String? {
        if !suffix.contains("/"), suffix.hasPrefix("libswift"), suffix.hasSuffix(".dylib") {
            let ios = iOSSupportSwiftDirectory + "/" + suffix
            let mac = macOSSwiftDirectory + "/" + suffix
            if catalystFrameworkOverlays.contains(suffix), systemLibraryExists(ios) { return ios }
            if systemLibraryExists(mac) { return mac }
            return systemLibraryExists(ios) ? ios : nil
        }
        // Only use the system counterpart of a canonical public framework install name.
        let parts = suffix.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[1].isEmpty, parts[0] == parts[1] + ".framework" else { return nil }
        let path = "/System/Library/Frameworks/" + suffix
        let ios = catalystSystemRoot + path
        if systemLibraryExists(ios) { return ios }
        return systemLibraryExists(path) ? path : nil
    }

    /// Carries the same repair forward to already-installed Catalyst images.
    static func repairSystemLibraryAliases(in macho: URL, app: URL) throws -> Bool {
        var binary = try Data(contentsOf: macho, options: .mappedIfSafe)
        guard try resolveSystemLibraryAliases(&binary, at: macho, in: app, copyBeforeWriting: true) else {
            return false
        }
        let permissions = try FileManager.default.attributesOfItem(atPath: macho.path)[.posixPermissions]
        try binary.write(to: macho, options: .atomic)
        if let permissions = permissions {
            try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: macho.path)
        }
        return true
    }

    private struct LoadCommandEdit {
        let range: Range<Int>
        let bytes: Data
    }

    private static func dylibReplacementEdit(
        in binary: Data, offset: Int, shouldSwap: Bool, macho: URL, searchDirectories: [URL]
    ) throws -> LoadCommandEdit? {
        let commandSize = MemoryLayout<dylib_command>.size
        let load = binary.extract(load_command.self, offset: offset, swap: shouldSwap ? swap_load_command : nil)
        guard load.cmd == UInt32(LC_LOAD_DYLIB) || load.cmd == LC_LOAD_WEAK_DYLIB else { return nil }
        guard load.cmdsize > commandSize else { throw PlayCoverError.appCorrupted }
        var command = binary.extract(dylib_command.self, offset: offset, swap: shouldSwap ? swap_dylib_command : nil)
        let nameOffset = Int(command.dylib.name.offset)
        guard nameOffset >= commandSize, nameOffset < Int(load.cmdsize) else { throw PlayCoverError.appCorrupted }
        let end = offset + Int(load.cmdsize)
        let name = binary[(offset + nameOffset)..<end]
        guard let terminator = name.firstIndex(of: 0),
              let path = String(data: name[..<terminator], encoding: .utf8) else {
            throw PlayCoverError.appCorrupted
        }
        let rpathPrefix = "@rpath/"
        guard path.hasPrefix(rpathPrefix) else { return nil }
        let suffix = String(path.dropFirst(rpathPrefix.count))
        guard let replacement = hostedLibraryInstallName(for: suffix),
              !isLibraryPresentInSearchDirectories(
                suffix: suffix, replacement: replacement, macho: macho, searchDirectories: searchDirectories
              ) else { return nil }
        let nameBytes = Data(replacement.utf8)
        let padding = 8 - (nameBytes.count % 8)
        command.dylib.name = lc_str(offset: UInt32(commandSize))
        command.cmdsize = UInt32(max(Int(load.cmdsize), commandSize + nameBytes.count + padding))
        let zeros = Int(command.cmdsize) - commandSize - nameBytes.count
        if shouldSwap { swap_dylib_command(&command, NX_BigEndian) }
        var bytes = Data(bytes: &command, count: commandSize)
        bytes.append(nameBytes)
        bytes.append(Data(count: zeros))
        return LoadCommandEdit(range: offset..<end, bytes: bytes)
    }

    private static func isLibraryPresentInSearchDirectories(
        suffix: String, replacement: String, macho: URL, searchDirectories: [URL]
    ) -> Bool {
        searchDirectories.contains { directory in
            let candidate = directory.appendingPathComponent(suffix).standardizedFileURL
            if candidate == macho.standardizedFileURL { return false }
            if catalystFrameworkOverlays.contains(suffix),
               candidate.path == macOSSwiftDirectory + "/" + suffix,
               replacement.hasPrefix(iOSSupportSwiftDirectory + "/") { return false }
            return systemLibraryExists(candidate.path)
        }
    }

    private static func resolveSystemLibraryAliases(
        _ binary: inout Data, at macho: URL, in app: URL?, copyBeforeWriting: Bool = false
    ) throws -> Bool {
        let headerSize = MemoryLayout<mach_header_64>.size
        guard let searchDirectories = appLibrarySearchDirectories(at: macho, in: app, binary: binary) else {
            return false
        }
        var changes: [LoadCommandEdit] = []
        var capturedError: Error?
        var reversedByteOrder = false
        let oldEnd = try iterateLoadCommands(binary: binary) { offset, shouldSwap in
            reversedByteOrder = shouldSwap
            do {
                if let edit = try dylibReplacementEdit(
                    in: binary, offset: offset, shouldSwap: shouldSwap,
                    macho: macho, searchDirectories: searchDirectories
                ) {
                    changes.append(edit)
                }
                return false
            } catch {
                capturedError = error
                return true
            }
        }
        if let capturedError { throw capturedError }
        guard !changes.isEmpty else { return false }
        var commands = Data()
        var cursor = headerSize
        for change in changes {
            commands.append(binary[cursor..<change.range.lowerBound])
            commands.append(change.bytes)
            cursor = change.range.upperBound
        }
        commands.append(binary[cursor..<oldEnd])
        if copyBeforeWriting { binary = binary.withUnsafeBytes { Data($0) } }
        do {
            try writeLoadCommands(&binary, commands: commands, start: headerSize, oldEnd: oldEnd,
                                  shouldSwap: reversedByteOrder)
        } catch is InsufficientLoadCommandSpace {
            return false
        }
        return true
    }

    // iOS and Mac Catalyst share SDK version numbers for the modern UIKit
    // compatibility modes. Preserve those SDKs when converting from iOS.
    private static let modernUIKitSDK: UInt32 = 26 << 16
    private static let legacyCatalystSDK: UInt32 = 14 << 16
    private static let catalystDeploymentTarget: UInt32 = 11 << 16

    static func replaceVersionCommand(_ binary: inout Data) throws {

        var macCatalystCommand = build_version_command(cmd: UInt32(LC_BUILD_VERSION),
                                                       cmdsize: 24,
                                                       platform: UInt32(PLATFORM_MACCATALYST),
                                                       minos: catalystDeploymentTarget,
                                                       sdk: legacyCatalystSDK,
                                                       ntools: 0)

        try replaceLastCommand(&binary, satisfy: {data, shouldSwap in
            let loadCommand = data.extract(load_command.self,
                                           offset: data.startIndex,
                                           swap: shouldSwap ? swap_load_command:nil)
            if loadCommand.cmd == UInt32(LC_BUILD_VERSION),
               data.count >= MemoryLayout<build_version_command>.size {
                let original = data.extract(build_version_command.self, offset: data.startIndex,
                                            swap: shouldSwap ? swap_build_version_command : nil)
                if original.platform == PLATFORM_IOS && original.sdk >= modernUIKitSDK {
                    macCatalystCommand.sdk = original.sdk
                }
            }
            return [UInt32(LC_VERSION_MIN_IPHONEOS),
                    UInt32(LC_VERSION_MIN_MACOSX),
                    UInt32(LC_BUILD_VERSION)]
                .contains(loadCommand.cmd)

        }, with: {shouldSwap in
            if shouldSwap {
                swap_build_version_command(&macCatalystCommand, NX_BigEndian)
            }
            return Data(bytes: &macCatalystCommand, count: MemoryLayout<build_version_command>.size)
        }, atEnd: true)
    }

    static func replaceLastCommand(_ binary: inout Data,
                                   satisfy isTargetCommand: (Data, Bool) -> Bool,
                                   with getNewCommandData: (Bool) -> Data?,
                                   atEnd shouldAppend: Bool) throws {
        let headerSize = MemoryLayout<mach_header_64>.size
        var header = binary.extract(mach_header_64.self)
        let shouldSwap = header.magic == MH_CIGAM_64
        if shouldSwap { swap_mach_header_64(&header, NXHostByteOrder()) }

        var oldCommandStart = headerSize
        var oldCommandSize: UInt32 = 0

        let movedCommandsEnd = try iterateLoadCommands(binary: binary) { offset, needSwap in
            let loadCommand = binary.extract(load_command.self,
                                             offset: offset,
                                             swap: needSwap ? swap_load_command:nil)
            if isTargetCommand(binary[offset ..< offset+Int(loadCommand.cmdsize)], needSwap) {
                oldCommandStart = offset
                oldCommandSize = loadCommand.cmdsize
            }
            return false
        }
        guard movedCommandsEnd == headerSize + Int(header.sizeofcmds) else {
            throw PlayCoverError.appCorrupted
        }

        let oldCommandEnd = oldCommandStart + Int(oldCommandSize)
        guard let newCommandData = getNewCommandData(shouldSwap) else { return }

        var resultingCommandsData = binary[oldCommandEnd..<movedCommandsEnd]
        if shouldAppend {
            resultingCommandsData.append(newCommandData)
        } else {
            resultingCommandsData.insert(contentsOf: newCommandData, at: resultingCommandsData.startIndex)
        }
        try writeLoadCommands(&binary, commands: resultingCommandsData, start: oldCommandStart,
                              oldEnd: movedCommandsEnd, shouldSwap: shouldSwap,
                              addsCommand: oldCommandSize == 0)
    }

    private struct InsufficientLoadCommandSpace: LocalizedError {
        var errorDescription: String? { "The Mach-O has insufficient header space for its load commands." }
    }

    private static func writeLoadCommands(
        _ binary: inout Data, commands: Data, start: Int, oldEnd: Int, shouldSwap: Bool, addsCommand: Bool = false
    ) throws {
        let headerSize = MemoryLayout<mach_header_64>.size
        let newEnd = start + commands.count
        if newEnd > oldEnd {
            guard newEnd <= binary.count, newEnd <= (try firstFileDataOffset(in: binary)),
                  binary[oldEnd..<newEnd].allSatisfy({ $0 == 0 }) else {
                throw InsufficientLoadCommandSpace()
            }
        }

        var header = binary.extract(mach_header_64.self, swap: shouldSwap ? swap_mach_header_64 : nil)
        guard oldEnd == headerSize + Int(header.sizeofcmds),
              let commandSize = UInt32(exactly: newEnd - headerSize) else {
            throw PlayCoverError.appCorrupted
        }
        header.sizeofcmds = commandSize
        if addsCommand { header.ncmds += 1 }
        if shouldSwap { swap_mach_header_64(&header, NX_BigEndian) }

        if newEnd < oldEnd {
            binary.replaceSubrange(newEnd..<oldEnd, with: Data(count: oldEnd - newEnd))
        }
        binary.replaceSubrange(start..<newEnd, with: commands)
        binary.replaceSubrange(0..<headerSize, with: Data(bytes: &header, count: headerSize))
    }

    private static func firstFileDataOffset(in binary: Data) throws -> Int {
        let segmentSize = MemoryLayout<segment_command_64>.size
        let sectionSize = MemoryLayout<section_64>.size
        var firstOffset: Int?
        var malformed = false
        _ = try iterateLoadCommands(binary: binary) { offset, shouldSwap in
            let load = binary.extract(load_command.self, offset: offset, swap: shouldSwap ? swap_load_command : nil)
            guard load.cmd == UInt32(LC_SEGMENT_64) else { return false }
            guard Int(load.cmdsize) >= segmentSize else {
                malformed = true
                return true
            }

            let segment = binary.extract(segment_command_64.self, offset: offset,
                                         swap: shouldSwap ? swap_segment_command_64 : nil)
            let sectionCount = Int(segment.nsects)
            guard sectionCount <= (Int(load.cmdsize) - segmentSize) / sectionSize else {
                malformed = true
                return true
            }
            if segment.fileoff > 0, segment.filesize > 0, let fileOffset = Int(exactly: segment.fileoff) {
                firstOffset = min(firstOffset ?? fileOffset, fileOffset)
            }
            for index in 0..<sectionCount {
                let sectionStart = offset + segmentSize + index * sectionSize
                let section = binary.extract(section_64.self, offset: sectionStart,
                                             swap: shouldSwap ? { swap_section_64($0, 1, $1) } : nil)
                let sectionOffset = Int(section.offset)
                if sectionOffset > 0, section.size > 0 {
                    firstOffset = min(firstOffset ?? sectionOffset, sectionOffset)
                }
            }
            return false
        }
        guard !malformed else { throw PlayCoverError.appCorrupted }
        guard let firstOffset = firstOffset, firstOffset <= binary.count else {
            throw InsufficientLoadCommandSpace()
        }
        return firstOffset
    }

    static func iterateLoadCommands(binary: Data, _ evaluate: (Int, Bool) -> Bool) throws -> Int {
        let headerSize = MemoryLayout<mach_header_64>.size
        guard binary.count >= headerSize else { throw PlayCoverError.appCorrupted }
        var header = binary.extract(mach_header_64.self)
        var offset = headerSize
        let shouldSwap = header.magic == MH_CIGAM_64
        guard header.magic == MH_MAGIC_64 || shouldSwap else { throw PlayCoverError.appCorrupted }
        if shouldSwap {
            swap_mach_header_64(&header, NXHostByteOrder())
            print("Slim Mach-O has reversed byte order")
        }

        let allCommandsEnd = headerSize + Int(header.sizeofcmds)
        if allCommandsEnd > binary.count || allCommandsEnd <= headerSize {
            print("Cannot iterate load commands: Mach-O file is corrupted(-1)")
            throw PlayCoverError.appCorrupted
        }
        for index in 0..<header.ncmds {
            let loadCommandSize = MemoryLayout<load_command>.size
            guard offset + loadCommandSize <= allCommandsEnd else { throw PlayCoverError.appCorrupted }
            let loadCommand = binary.extract(load_command.self,
                                             offset: offset,
                                             swap: shouldSwap ? swap_load_command:nil)
            let commandEnd = offset + Int(loadCommand.cmdsize)
            if commandEnd > allCommandsEnd || loadCommand.cmdsize < loadCommandSize {
                print("Cannot iterate load commands: Mach-O file is corrupted(\(index))")
                throw PlayCoverError.appCorrupted
            }
            let terminated = evaluate(offset, shouldSwap)
            offset = commandEnd
            if terminated { return offset }
        }
        guard offset == allCommandsEnd else { throw PlayCoverError.appCorrupted }
        return offset
    }

    static func isMachoEncrypted(atURL url: URL) throws -> Bool {
        var binary = try Data(contentsOf: url, options: .mappedIfSafe)
        try stripBinary(&binary)
        var result = false
        _ = try iterateLoadCommands(binary: binary) { offset, shouldSwap in
            let loadCommand = binary.extract(load_command.self,
                                             offset: offset,
                                             swap: shouldSwap ? swap_load_command:nil)
            if loadCommand.cmd == UInt32(LC_ENCRYPTION_INFO_64) {
                let infoCommand = binary.extract(encryption_info_command_64.self,
                                                 offset: offset,
                                                 swap: shouldSwap ? swap_encryption_command_64:nil)
                result = infoCommand.cryptid != 0
                return true
            }
            return false
        }
        return result
    }

    static func isMachoValidArch(_ url: URL, allowingUniversal: Bool = false) throws -> Bool {
        var binary = try Data(contentsOf: url, options: .mappedIfSafe)
        guard binary.count >= MemoryLayout<mach_header_64>.size else { return false }
        if allowingUniversal {
            do {
                try stripBinary(&binary)
            } catch PlayCoverError.failedToStripBinary {
                return false
            }
            guard binary.count >= MemoryLayout<mach_header_64>.size else { return false }
        }
        var header = binary.extract(mach_header_64.self)
        let shouldSwap = header.magic == MH_CIGAM_64
        guard header.magic == MH_MAGIC_64 || shouldSwap else { return false }
        if shouldSwap { swap_mach_header_64(&header, NXHostByteOrder()) }
        return try header.cputype == CPU_TYPE_ARM64 && isCatalyst(binary)
    }

    private static func isCatalyst(_ binary: Data) throws -> Bool {
        var result = false
        var malformed = false
        _ = try iterateLoadCommands(binary: binary) { offset, shouldSwap in
            let loadCommand = binary.extract(load_command.self, offset: offset,
                                             swap: shouldSwap ? swap_load_command : nil)
            guard loadCommand.cmd == UInt32(LC_BUILD_VERSION) else { return false }
            guard loadCommand.cmdsize >= MemoryLayout<build_version_command>.size else {
                malformed = true
                return true
            }
            let versionCommand = binary.extract(build_version_command.self, offset: offset,
                                                swap: shouldSwap ? swap_build_version_command : nil)
            result = versionCommand.platform == PLATFORM_MACCATALYST
            return true
        }
        guard !malformed else { throw PlayCoverError.appCorrupted }
        return result
    }
}

extension Macho {
    private static let restrictSegBytes = paddedMachOName("__RESTRICT")
    private static let restrictSectBytes = paddedMachOName("__restrict")
    private static let replacementSegBytes = paddedMachOName("__PLAYCVR")
    private static let replacementSectBytes = paddedMachOName("__playcvr")

    @discardableResult
    static func stripRestrictSegment(atURL macho: URL) throws -> Bool {
        // Almost every warm launch is a no-op. Inspect mapped header pages instead of
        // allocating and reading hundreds of MB of executable code into the launcher.
        var binary = try Data(contentsOf: macho, options: .mappedIfSafe)
        guard try stripRestrictSegment(&binary, applyChanges: false) else { return false }
        // Inspection never mutates mapped pages. Only the rare repair needs an owned copy.
        binary = binary.withUnsafeBytes { Data($0) }
        guard try stripRestrictSegment(&binary) else { return false }
        let permissions = try FileManager.default.attributesOfItem(atPath: macho.path)[.posixPermissions]
        try binary.write(to: macho, options: .atomic)
        if let permissions {
            try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: macho.path)
        }
        return true
    }

    /// Renames any `__RESTRICT` / `__restrict` segment and section names in-place so macOS
    /// dyld permits `@rpath` expansion and `DYLD_INSERT_LIBRARIES` on ad-hoc signed apps.
    @discardableResult
    static func stripRestrictSegment(_ binary: inout Data) throws -> Bool {
        try stripRestrictSegment(&binary, applyChanges: true)
    }

    private static func stripRestrictSegment(_ binary: inout Data, applyChanges: Bool) throws -> Bool {
        guard binary.count >= MemoryLayout<UInt32>.size else { return false }

        let magic = binary.extract(UInt32.self)
        if magic == FAT_MAGIC || magic == FAT_CIGAM {
            return try stripRestrictSegmentInFat(&binary, applyChanges: applyChanges)
        }
        return try stripRestrictSegmentInSlice(&binary, sliceStart: 0, sliceEnd: binary.count,
                                             applyChanges: applyChanges)
    }

    private static func stripRestrictSegmentInFat(_ binary: inout Data, applyChanges: Bool) throws -> Bool {
        var header = binary.extract(fat_header.self)
        let shouldSwap = header.magic == FAT_CIGAM
        if shouldSwap { swap_fat_header(&header, NXHostByteOrder()) }

        var offset = MemoryLayout.size(ofValue: header)
        var modified = false
        for _ in 0..<header.nfat_arch {
            guard offset + MemoryLayout<fat_arch>.size <= binary.count else { break }
            var arch = binary.extract(fat_arch.self, offset: offset)
            if shouldSwap { swap_fat_arch(&arch, 1, NXHostByteOrder()) }
            let sliceStart = Int(arch.offset)
            let sliceEnd = sliceStart + Int(arch.size)
            if sliceStart >= 0 && sliceEnd <= binary.count && sliceStart < sliceEnd,
               try stripRestrictSegmentInSlice(&binary, sliceStart: sliceStart, sliceEnd: sliceEnd,
                                              applyChanges: applyChanges) {
                modified = true
            }
            offset += MemoryLayout<fat_arch>.size
        }
        return modified
    }

    private static func stripRestrictSegmentInSlice(
        _ binary: inout Data, sliceStart: Int, sliceEnd: Int, applyChanges: Bool
    ) throws -> Bool {
        let headerSize = MemoryLayout<mach_header_64>.size
        guard sliceEnd - sliceStart >= headerSize else { return false }
        var header = binary.extract(mach_header_64.self, offset: sliceStart)
        let shouldSwap = header.magic == MH_CIGAM_64
        guard header.magic == MH_MAGIC_64 || shouldSwap else { return false }
        if shouldSwap { swap_mach_header_64(&header, NXHostByteOrder()) }
        let commandsEnd = sliceStart + headerSize + Int(header.sizeofcmds)
        guard commandsEnd <= sliceEnd && commandsEnd > sliceStart + headerSize else { return false }
        var offset = sliceStart + headerSize
        var modified = false
        for _ in 0..<header.ncmds {
            guard offset + MemoryLayout<load_command>.size <= commandsEnd else { break }
            let loadCommand = binary.extract(load_command.self, offset: offset,
                                             swap: shouldSwap ? swap_load_command : nil)
            let commandEnd = offset + Int(loadCommand.cmdsize)
            guard commandEnd <= commandsEnd && commandEnd > offset else { break }
            if loadCommand.cmd == UInt32(LC_SEGMENT_64),
               offset + MemoryLayout<segment_command_64>.size <= commandEnd,
               binary[(offset + 8)..<(offset + 24)] == restrictSegBytes {
                if !applyChanges { return true }
                binary.replaceSubrange((offset + 8)..<(offset + 24), with: replacementSegBytes)
                let seg = binary.extract(segment_command_64.self, offset: offset,
                                         swap: shouldSwap ? swap_segment_command_64 : nil)
                renameRestrictSections(in: &binary, segOffset: offset, commandEnd: commandEnd, nsects: Int(seg.nsects))
                modified = true
            }
            offset = commandEnd
        }
        return modified
    }

    private static func renameRestrictSections(in binary: inout Data, segOffset: Int, commandEnd: Int, nsects: Int) {
        var sectOffset = segOffset + MemoryLayout<segment_command_64>.size
        let sectSize = MemoryLayout<section_64>.size
        for _ in 0..<nsects {
            guard sectOffset + sectSize <= commandEnd else { break }
            if binary[sectOffset..<(sectOffset + 16)] == restrictSectBytes {
                binary.replaceSubrange(sectOffset..<(sectOffset + 16), with: replacementSectBytes)
            }
            if binary[(sectOffset + 16)..<(sectOffset + 32)] == restrictSegBytes {
                binary.replaceSubrange((sectOffset + 16)..<(sectOffset + 32), with: replacementSegBytes)
            }
            sectOffset += sectSize
        }
    }

    private static func paddedMachOName(_ name: String) -> Data {
        var bytes = Data(name.utf8.prefix(16))
        if bytes.count < 16 { bytes.append(Data(count: 16 - bytes.count)) }
        return bytes
    }
}
