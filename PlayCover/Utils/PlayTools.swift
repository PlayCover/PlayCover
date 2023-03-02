//
//  PlayTools.swift
//  PlayCover
//

import Foundation
import injection

// swiftlint:disable type_body_length
// swiftlint:disable file_length
// swiftlint:disable function_body_length
// swiftlint:disable force_unwrapping

class PlayTools {
    private static let frameworksURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library")
        .appendingPathComponent("Frameworks")
    private static let playToolsFramework = frameworksURL
        .appendingPathComponent("PlayTools")
        .appendingPathExtension("framework")
    private static let playToolsPath = playToolsFramework
        .appendingPathComponent("PlayTools")
    private static let akInterfacePath = playToolsFramework
        .appendingPathComponent("PlugIns")
        .appendingPathComponent("AKInterface")
        .appendingPathExtension("bundle")
    private static let bundledPlayToolsFramework = Bundle.main.bundleURL
        .appendingPathComponent("Contents")
        .appendingPathComponent("Frameworks")
        .appendingPathComponent("PlayTools")
        .appendingPathExtension("framework")

    public static var playCoverContainer: URL {
        let playCoverPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("io.playcover.PlayCover")
        if !FileManager.default.fileExists(atPath: playCoverPath.path) {
            do {
                try FileManager.default.createDirectory(at: playCoverPath,
                                                        withIntermediateDirectories: true,
                                                        attributes: [:])
            } catch {
                Log.shared.error(error)
            }
        }

        return playCoverPath
    }

    static func installOnSystem() {
        Task(priority: .background) {
            do {
                Log.shared.log("Installing PlayTools")

                // Check if Frameworks folder exists, if not, create it
                if !FileManager.default.fileExists(atPath: frameworksURL.path) {
                    try FileManager.default.createDirectory(
                        atPath: frameworksURL.path,
                        withIntermediateDirectories: true,
                        attributes: [:])
                }

                // Check if a version of PlayTools is already installed, if so remove it
                FileManager.default.delete(at: URL(fileURLWithPath: playToolsFramework.path))

                // Install version of PlayTools bundled with PlayCover
                Log.shared.log("Copying PlayTools to Frameworks")
                if FileManager.default.fileExists(atPath: playToolsFramework.path) {
                    try FileManager.default.removeItem(at: playToolsFramework)
                }
                try FileManager.default.copyItem(at: bundledPlayToolsFramework, to: playToolsFramework)
            } catch {
                Log.shared.error(error)
            }
        }
    }

    static func stripBinary(_ binary: inout Data) throws {
        var header = binary.extract(fat_header.self)
        var offset = MemoryLayout.size(ofValue: header)
        let shouldSwap = header.magic == FAT_CIGAM

        if header.magic == FAT_MAGIC || header.magic == FAT_CIGAM {
            // Make sure the endianness is correct
            if shouldSwap {
                swap_fat_header(&header, NXHostByteOrder())
            }

            for _ in 0..<header.nfat_arch {
                var arch = binary.extract(fat_arch.self, offset: offset)
                if shouldSwap {
                    swap_fat_arch(&arch, 1, NXHostByteOrder())
                }

                if arch.cputype == CPU_TYPE_ARM64 {
                    print("Found ARM64 arch in fat binary")

                    binary = binary
                        .subdata(in: Int(arch.offset)..<Int(arch.offset+arch.size))

                    return
                }

                offset += Int(MemoryLayout.size(ofValue: arch))
            }

            throw PlayCoverError.failedToStripBinary
        }
    }

    static func installInIPA(_ exec: URL) throws {
        var binary = try Data(contentsOf: exec)
        try stripBinary(&binary)

        Inject.injectMachO(machoPath: exec.path,
                           cmdType: LC_Type.LOAD_DYLIB,
                           backup: false,
                           injectPath: playToolsPath.path,
                           finishHandle: { result in
            if result {
                do {
                    try installPluginInIPA(exec.deletingLastPathComponent())
                    try Shell.signApp(exec)
                } catch {
                    Log.shared.error(error)
                }
            }
        })
    }

    static func installPluginInIPA(_ payload: URL) throws {
        let pluginsURL = payload.appendingPathComponent("PlugIns")
        if !FileManager.default.fileExists(atPath: pluginsURL.path) {
            try FileManager.default.createDirectory(at: pluginsURL, withIntermediateDirectories: true)
        }

        let bundleTarget = pluginsURL
            .appendingPathComponent("AKInterface")
            .appendingPathExtension("bundle")

        let akInterface = bundledPlayToolsFramework.appendingPathComponent("PlugIns")
            .appendingPathComponent("AKInterface")
            .appendingPathExtension("bundle")

        if FileManager.default.fileExists(atPath: bundleTarget.path) {
            try FileManager.default.removeItem(at: bundleTarget)
        }
        try FileManager.default.copyItem(at: akInterface, to: bundleTarget)
        try bundleTarget.fixExecutable()
        try Shell.signMacho(bundleTarget)
    }

    static func injectInIPA(_ exec: URL, payload: URL) throws {
        var binary = try Data(contentsOf: exec)
        try stripBinary(&binary)

        Inject.injectMachO(machoPath: exec.path,
                           cmdType: LC_Type.LOAD_DYLIB,
                           backup: false,
                           injectPath: "@executable_path/Frameworks/PlayTools.dylib",
                           finishHandle: { result in
            if result {
                Task(priority: .background) {
                    do {
                        if !FileManager.default.fileExists(atPath: payload.appendingPathComponent("Frameworks").path) {
                            try FileManager.default.createDirectory(
                                at: payload.appendingPathComponent("Frameworks"),
                                withIntermediateDirectories: true)
                        }
                        if !FileManager.default.fileExists(atPath: payload.appendingPathComponent("PlugIns").path) {
                            try FileManager.default.createDirectory(
                                at: payload.appendingPathComponent("PlugIns"),
                                withIntermediateDirectories: true)
                        }

                        let libraryTarget = payload.appendingPathComponent("Frameworks")
                            .appendingPathComponent("PlayTools")
                            .appendingPathExtension("dylib")
                        let bundleTarget = payload.appendingPathComponent("PlugIns")
                            .appendingPathComponent("AKInterface")
                            .appendingPathExtension("bundle")

                        let tools = bundledPlayToolsFramework
                            .appendingPathComponent("PlayTools")
                        let akInterface = bundledPlayToolsFramework.appendingPathComponent("PlugIns")
                            .appendingPathComponent("AKInterface")
                            .appendingPathExtension("bundle")

                        if FileManager.default.fileExists(atPath: libraryTarget.path) {
                            try FileManager.default.removeItem(at: libraryTarget)
                        }
                        try FileManager.default.copyItem(at: tools, to: libraryTarget)

                        if FileManager.default.fileExists(atPath: bundleTarget.path) {
                            try FileManager.default.removeItem(at: bundleTarget)
                        }
                        try FileManager.default.copyItem(at: akInterface, to: bundleTarget)

                        try libraryTarget.fixExecutable()
                        try bundleTarget.fixExecutable()
                        try Shell.signMacho(bundleTarget)
                    } catch {
                        Log.shared.error(error)
                    }
                }
            }
        })
    }

    static func removeFromApp(_ exec: URL) {
        Inject.removeMachO(machoPath: exec.path,
                           cmdType: LC_Type.LOAD_DYLIB,
                           backup: false,
                           injectPath: playToolsPath.path,
                           finishHandle: { result in
            if result {
                do {
                    let pluginUrl = exec.deletingLastPathComponent()
                        .appendingPathComponent("PlugIns")
                        .appendingPathComponent("AKInterface")
                        .appendingPathExtension("bundle")

                    if FileManager.default.fileExists(atPath: pluginUrl.path) {
                        try FileManager.default.removeItem(at: pluginUrl)
                    }

                    try Shell.signApp(exec)
                } catch {
                    Log.shared.error(error)
                }
            }
        })
    }

    static func convertMacho(_ macho: URL) throws {
        print("Converting MachO at \(macho.path)")

        var binary = try Data(contentsOf: macho)

        print("Stripping MachO...")
        try stripBinary(&binary)
        print("Replacing version command...")
        try replaceVersionCommand(&binary)
        print("Replacing instances of @rpath dylibs...")
        try replaceLibraries(&binary)

        print("Writing revised MachO...")
        try FileManager.default.removeItem(at: macho)
        try binary.write(to: macho)
    }

    static func replaceLibraries(_ binary: inout Data) throws {
        let dylibsToReplace = ["libswiftUIKit"]

        for dylib in dylibsToReplace {
            let rpathDylib = "@rpath/\(dylib).dylib"
            let libDylib = "/System/iOSSupport/usr/lib/swift/\(dylib).dylib"

            // 1. Check if dylib LC exists
            // 2. If it exists, take note if it is weak or strong and copy version info
            // 3. Replace existing LC

            try replaceLibrary(&binary, rpathDylib, libDylib)
        }
    }

    static func replaceLibrary(_ binary: inout Data, _ rpath: String, _ lib: String) throws {
        var start: Int?
        var size: Int?
        var isWeak: Bool = false
        var dylibExists: Bool = false
        var dylib: dylib?
        var oldDylibLength: UInt32 = 0

        let machoRange = Range(NSRange(location: 0, length: MemoryLayout<mach_header_64>.size))!
        var header = binary.extract(mach_header_64.self)
        var offset = MemoryLayout.size(ofValue: header)

        // Perform steps 1-2
        for _ in 0..<header.ncmds {
            let loadCommand = binary.extract(load_command.self, offset: offset)
            switch UInt32(loadCommand.cmd) {
            case LC_LOAD_WEAK_DYLIB, UInt32(LC_LOAD_DYLIB):
                let dylibCommand = binary.extract(dylib_command.self, offset: offset)
                if String(data: binary,
                          offset: offset,
                          commandSize: Int(dylibCommand.cmdsize),
                          loadCommandString: dylibCommand.dylib.name) == rpath {

                    isWeak = LC_LOAD_WEAK_DYLIB == UInt32(loadCommand.cmd)
                    dylibExists = true
                    dylib = dylibCommand.dylib
                    oldDylibLength = UInt32(dylibCommand.cmdsize)

                    start = offset
                    size = Int(dylibCommand.cmdsize)
                }
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }

        if !dylibExists {
            // dylib with given rpath was not found in binary
            return
        }

        print("Found \(rpath) in binary")

        // Perform step 3
        let endOfHeader = offset
        let length = MemoryLayout<dylib_command>.size + lib.lengthOfBytes(using: String.Encoding.utf8)
        let padding = (8 - (length % 8))
        let cmdsize = length + padding

        dylib!.name = lc_str(offset: UInt32(MemoryLayout<dylib_command>.size))
        var command = dylib_command(cmd: isWeak ? LC_LOAD_WEAK_DYLIB : UInt32(LC_LOAD_DYLIB),
                                    cmdsize: UInt32(cmdsize),
                                    dylib: dylib!)

        if let startOfCmd = start,
           let sizeOfCmd = size {
            let endOfCmd = startOfCmd + sizeOfCmd

            let restOfHeader = Range(NSRange(location: endOfCmd, length: endOfHeader - endOfCmd))!

            var zero: UInt = 0
            var commandData = Data()
            commandData.append(Data(bytes: &command, count: MemoryLayout<dylib_command>.size))
            commandData.append(lib.data(using: String.Encoding.ascii) ?? Data())
            commandData.append(Data(bytes: &zero, count: padding))
            commandData.append(binary.subdata(in: restOfHeader))

            let newHeaderRange = Range(NSRange(location: startOfCmd,
                                               length: endOfHeader - endOfCmd + cmdsize))!

            binary.replaceSubrange(newHeaderRange, with: commandData)
        }

        // Write new header data
        header.sizeofcmds -= oldDylibLength
        header.sizeofcmds += UInt32(cmdsize)
        let newHeaderData = Data(bytes: &header, count: MemoryLayout<mach_header_64>.size)
        binary.replaceSubrange(machoRange, with: newHeaderData)
    }

    static func replaceVersionCommand(_ binary: inout Data) throws {
        var start: Int?
        var size: Int?
        var end: Int?
        var oldDylibLength: UInt32 = 0

        var header = binary.extract(mach_header_64.self)
        var offset = MemoryLayout.size(ofValue: header)
        let machoRange = Range(NSRange(location: 0, length: MemoryLayout<mach_header_64>.size))!

        for _ in 0..<header.ncmds {
            let loadCommand = binary.extract(load_command.self, offset: offset)
            switch UInt32(loadCommand.cmd) {
            case UInt32(LC_VERSION_MIN_IPHONEOS), UInt32(LC_VERSION_MIN_MACOSX):
                let versionCommand = binary.extract(version_min_command.self, offset: offset)

                start = offset
                size = Int(versionCommand.cmdsize)
                oldDylibLength = UInt32(versionCommand.cmdsize)
            case UInt32(LC_BUILD_VERSION):
                let versionCommand = binary.extract(build_version_command.self, offset: offset)

                start = offset
                size = Int(versionCommand.cmdsize)
                oldDylibLength = UInt32(versionCommand.cmdsize)
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }
        end = offset

        if let start = start,
           let end = end,
           let size = size {
            let subrangeNew = Range(NSRange(location: start + size, length: end - start - size))!
            let subrangeOld = Range(NSRange(location: start, length: end - start))!
            var zero: UInt = 0
            var commandData = Data()
            commandData.append(binary.subdata(in: subrangeNew))
            commandData.append(Data(bytes: &zero, count: size))

            binary.replaceSubrange(subrangeOld, with: commandData)
        }

        header.sizeofcmds -= oldDylibLength

        var versionCommand = build_version_command(cmd: UInt32(LC_BUILD_VERSION),
                                                   cmdsize: 24,
                                                   platform: UInt32(PLATFORM_MACCATALYST),
                                                   minos: 0x000b0000,
                                                   sdk: 0x000e0000,
                                                   ntools: 0)

        start = Int(header.sizeofcmds) + Int(MemoryLayout<mach_header_64>.size)

        header.sizeofcmds += versionCommand.cmdsize
        let newHeaderData = Data(bytes: &header, count: MemoryLayout<mach_header_64>.size)

        var commandData = Data()
        commandData.append(Data(bytes: &versionCommand, count: MemoryLayout<build_version_command>.size))

        let subrange = Range(NSRange(location: start!, length: commandData.count))!
        if binary.subdata(in: subrange).allSatisfy({ $0 == 0 }) {
            Log.shared.error("Failed to replace version command. Not enough space in binary!")
            return
        }

        binary.replaceSubrange(subrange, with: commandData)

        binary.replaceSubrange(machoRange, with: newHeaderData)
    }

    static func isMachoEncrypted(atURL url: URL) throws -> Bool {
        var binary = try Data(contentsOf: url)
        try stripBinary(&binary)

        return try isSlimMachoEncrypted(binary: binary)
    }

    static func isSlimMachoEncrypted(binary: Data) throws -> Bool {
        var offset = 0
        var header = binary.extract(mach_header_64.self, offset: offset)
        offset += MemoryLayout.size(ofValue: header)
        let shouldSwap = header.magic == MH_CIGAM_64

        if shouldSwap {
            swap_mach_header_64(&header, NXHostByteOrder())
        }

        for _ in 0..<header.ncmds {
            var loadCommand = binary.extract(load_command.self, offset: offset)
            if shouldSwap {
                swap_load_command(&loadCommand, NXHostByteOrder())
            }

            switch loadCommand.cmd {
            case UInt32(LC_ENCRYPTION_INFO_64):
                var infoCommand = binary.extract(encryption_info_command_64.self, offset: offset)
                if shouldSwap {
                    swap_encryption_command_64(&infoCommand, NXHostByteOrder())
                }

                return infoCommand.cryptid != 0
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }

        return false
    }

    static func isMachoValidArch(_ url: URL) throws -> Bool {
        var binary = try Data(contentsOf: url)
        try stripBinary(&binary)

        return try isSlimMachoValidArch(binary: binary)
    }

    static func isSlimMachoValidArch(binary: Data) throws -> Bool {
        var offset = 0
        var header = binary.extract(mach_header_64.self, offset: offset)
        offset += MemoryLayout.size(ofValue: header)
        let shouldSwap = header.magic == MH_CIGAM_64

        if shouldSwap {
            swap_mach_header_64(&header, NXHostByteOrder())
        }

        for _ in 0..<header.ncmds {
            var loadCommand = binary.extract(load_command.self, offset: offset)
            if shouldSwap {
                swap_load_command(&loadCommand, NXHostByteOrder())
            }

            switch loadCommand.cmd {
            case UInt32(LC_BUILD_VERSION):
                var versionCommand = binary.extract(build_version_command.self, offset: offset)
                if shouldSwap {
                    swap_build_version_command(&versionCommand, NXHostByteOrder())
                }

                return versionCommand.platform == PLATFORM_MACCATALYST
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }

        return false
    }

    static func installedInExec(atURL url: URL) throws -> Bool {
        var binary = try Data(contentsOf: url)
        try stripBinary(&binary)

        var header = binary.extract(mach_header_64.self)
        var offset = MemoryLayout.size(ofValue: header)
        let shouldSwap = header.magic == MH_CIGAM_64

        if shouldSwap {
            swap_mach_header_64(&header, NXHostByteOrder())
        }

        for _ in 0..<header.ncmds {
            var loadCommand = binary.extract(load_command.self, offset: offset)
            if shouldSwap {
                swap_load_command(&loadCommand, NXHostByteOrder())
            }

            switch loadCommand.cmd {
            case UInt32(LC_LOAD_DYLIB):
                var dylibCommand = binary.extract(dylib_command.self, offset: offset)
                if shouldSwap {
                    swap_dylib_command(&dylibCommand, NXHostByteOrder())
                }

                let dylibName = String(data: binary,
                                       offset: offset,
                                       commandSize: Int(dylibCommand.cmdsize),
                                       loadCommandString: dylibCommand.dylib.name)
                if dylibName == playToolsPath.esc {
                    return true
                }
            default:
                break
            }
            offset += Int(loadCommand.cmdsize)
        }

        return false
    }

    static func isInstalled() throws -> Bool {
        try FileManager.default.fileExists(atPath: playToolsPath.path)
            && FileManager.default.fileExists(atPath: akInterfacePath.path)
            && isMachoValidArch(playToolsPath)
    }

	static func fetchEntitlements(_ exec: URL) throws -> String {
        do {
            return try Shell.run("/usr/bin/codesign", "-d", "--entitlements", "-", "--xml", exec.path)
        } catch {
            if error.localizedDescription.contains("Document is empty") {
                // Empty entitlements
                return ""
            } else {
                throw error
            }
        }
	}
}
