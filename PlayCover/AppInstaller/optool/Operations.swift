//
//  Operations.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 20/09/2022.
//

import Foundation

class Operations {
    @discardableResult
    public static func removeLoadEntryFromBinary(_ binary: inout OffsetNSData,
                                                 _ inputMacho: thin_header,
                                                 _ payload: String) -> Bool {
        var macho = inputMacho
        binary.offset = Int(macho.offset + macho.size)

        var num: UInt32 = 0
        var cumulativeSize: UInt32 = 0
        var removedOrdinal: UInt32 = UInt32.max

        for index in 0..<macho.header.ncmds {
            if binary.offset >= binary.data.length
                || binary.offset > macho.offset + macho.size + macho.header.sizeofcmds {
                break
            }

            let cmd: UInt32 = binary.intAtOffset(offset: binary.offset)
            let size: UInt32 = binary.intAtOffset(offset: binary.offset + 4)

            switch cmd {
            case LC_REEXPORT_DYLIB,
            LC_LOAD_UPWARD_DYLIB,
            LC_LOAD_WEAK_DYLIB,
            UInt32(LC_LOAD_DYLIB):
                let command: dylib_command = (binary.data.bytes + binary.offset).load(as: dylib_command.self)
                let name = binary.data.subdata(with:
                                                NSRange(location: binary.offset + Int(command.dylib.name.offset),
                                                        length: Int(command.cmdsize - command.dylib.name.offset)))
                    .withUnsafeBytes({ $0.load(as: UnsafeMutablePointer<CChar>.self) })
                if NSNumber(pointer: name).isEqual(to: payload) && removedOrdinal == UInt32.max {
                    print("Removing payload from \(Patch.loadCommand(cmd))...")
                    binary.data.replaceBytes(in: NSRange(location: binary.offset,
                                                         length: Int(size)), withBytes: nil, length: 0)
                    num += 1
                    cumulativeSize += size

                    removedOrdinal = index
                }

                binary.offset += Int(size)
            default:
                binary.offset += Int(size)
            }
        }

        if num == 0 {
            return false
        }

        macho.header.ncmds -= num
        macho.header.sizeofcmds -= cumulativeSize

        var zeroByte: UInt = 0
        binary.data.replaceBytes(in: NSRange(location: Int(macho.offset + macho.header.sizeofcmds + macho.size),
                                             length: 0), withBytes: &zeroByte,
                                 length: Int(cumulativeSize))
        binary.data.replaceBytes(in: NSRange(location: Int(macho.offset),
                                             length: MemoryLayout.size(ofValue: macho.header)),
                                 withBytes: &macho.header,
                                 length: MemoryLayout.size(ofValue: macho.header))

        return true
    }

    public static func binaryHasLoadCommandForDylib(binary: inout OffsetNSData,
                                                    dylib: String,
                                                    lastOffseet: inout UInt32?,
                                                    macho: thin_header) -> Bool {
        binary.offset = Int(macho.size + macho.offset)
        var loadOffset: UInt = UInt(binary.offset)

        for _ in 0..<macho.header.ncmds {
            if binary.offset >= binary.data.length
                || binary.offset > macho.offset + macho.size + macho.header.sizeofcmds {
                break
            }

            let cmd: UInt32 = binary.intAtOffset(offset: binary.offset)
            let size: UInt32 = binary.intAtOffset(offset: binary.offset + 4)

            switch cmd {
            case LC_REEXPORT_DYLIB,
            LC_LOAD_UPWARD_DYLIB,
            LC_LOAD_WEAK_DYLIB,
            UInt32(LC_LOAD_DYLIB):
                let command: dylib_command = (binary.data.bytes + binary
                    .offset).load(as: dylib_command.self)

                let name = binary.data.subdata(with:
                                                NSRange(location: binary.offset + Int(command.dylib.name.offset),
                                                        length: Int(command.cmdsize - command.dylib.name.offset)))
                    .withUnsafeBytes({ $0.load(as: UnsafeMutablePointer<CChar>.self) })
                if NSNumber(pointer: name).isEqual(to: dylib) {
                    lastOffseet = UInt32(binary.offset)
                    return true
                }

                binary.offset += Int(size)
                loadOffset = UInt(binary.offset)
            default:
                binary.offset += Int(size)
            }
        }

        if lastOffseet != nil {
            lastOffseet = UInt32(loadOffset)
        }

        return false
    }

    public static func insetLoadEntryIntoBinary(_ dylibPath: String,
                                                _ binary: inout OffsetNSData,
                                                _ inputMacho: thin_header) -> Bool {
        var macho = inputMacho
        var type: UInt32 = UInt32(LC_LOAD_DYLIB)

        // TODO: FIGURE OUT THIS VALUE
        var lastOffset: UInt32?
        if binaryHasLoadCommandForDylib(binary: &binary, dylib: dylibPath, lastOffseet: &lastOffset, macho: macho) {
            let originalType = (binary.data.bytes + Int(lastOffset ?? UInt32(binary.offset))).load(as: UInt32.self)
            if originalType != type {
                print("A load commmand already exists for \(dylibPath). Changing command type from \(Patch.loadCommand(originalType)) to desired \(Patch.loadCommand(type))")
                binary.data.replaceBytes(in: NSRange(location: Int(lastOffset ?? UInt32(binary.offset)), length: MemoryLayout.size(ofValue: type)), withBytes: &type)
            } else {
                print("Load command already exists")
            }

            return true
        }

        let length = UInt(MemoryLayout.stride(ofValue: dylib_command.self) + dylibPath.lengthOfBytes(using: .utf8))
        let padding = UInt(8 - (length % 8))

        let occupant: NSData = binary.data.subdata(with:
                                                    NSRange(location: Int(macho.header.sizeofcmds + macho.offset + macho.size),
                                                                 length: Int(length + padding))) as NSData

        if strcmp(occupant.bytes, "\0") != 0 {
            print("Cannot inject payload into \(dylibPath) because there is no room")
            return false
        }

        print("Inserting a \(Patch.loadCommand(type)) command for architecture: \(Patch.cpu(macho.header.cputype))")

        var command: dylib_command = dylib_command()
        var dylib: dylib = dylib()
        dylib.name.offset = UInt32(MemoryLayout.stride(ofValue: dylib_command.self))
        dylib.timestamp = 2
        dylib.current_version = 0
        dylib.compatibility_version = 0
        command.cmd = type
        command.dylib = dylib
        command.cmdsize = UInt32(length + padding)

        var zeroByte: UInt = 0
        let commandData: NSMutableData = NSMutableData()
        commandData.append(&command, length: MemoryLayout.stride(ofValue: dylib_command.self))
        commandData.append(dylibPath.data(using: .ascii)!)
        commandData.append(&zeroByte, length: Int(padding))

        binary.data.replaceBytes(in: NSRange(location: Int(macho.offset + macho.header.sizeofcmds + macho.size),
                                            length: commandData.length),
                                 withBytes: nil,
                                 length: 0)

        binary.data.replaceBytes(in: NSRange(location: Int(lastOffset ?? UInt32(binary.offset)),
                                            length: 0),
                                 withBytes: commandData.bytes,
                                 length: commandData.length)

        macho.header.ncmds += 1
        macho.header.sizeofcmds += command.cmdsize

        binary.data.replaceBytes(in: NSRange(location: Int(macho.offset),
                                             length: MemoryLayout.size(ofValue: macho.header)),
                                 withBytes: &macho.header)

        return true
    }
}
