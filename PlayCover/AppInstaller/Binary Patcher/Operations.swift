//
//  Operations.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 16/09/2022.
//

import Foundation

// swiftlint:disable function_body_length

class Operations {
    public static func insertLoadEntryIntroBinary(_ dylibPath: String,
                                                  _ binary: inout NSMutableData,
                                                  _ macho: inout thin_header) -> Bool {

        // Load command only initiated at isntall time, so the command should not already be present
        /*var lastOffset: UInt32 = 0
        if binaryHasLoadCommandForDylib(&binary, dylibPath, &lastOffset, macho) {
            let originalType: UInt32 = (binary.bytes + Int(lastOffset)).load(as: UInt32.self)
            if originalType != LC_LOAD_DYLIB {
                print("A load command already exists for \(dylibPath). "
                      + "Changing command type from \(LC(originalType)) to desired \(LC(UInt32(LC_LOAD_DYLIB)))")
                var typePointer = LC_LOAD_DYLIB
                binary.replaceBytes(in: NSRange(location: Int(lastOffset),
                                                length: MemoryLayout.size(ofValue: LC_LOAD_DYLIB)),
                                    withBytes: &typePointer)
            } else {
                print("Load command already exists")
            }
        }*/

        let length: UInt = UInt(MemoryLayout.stride(ofValue: dylib_command.self))
        let padding: UInt = (8 - (length % 8))
        print("Legnth: \(length)")
        print("Padding: \(padding)")

        /*let occupant = binary.subdata(with: NSRange(location: Int(macho.header.sizeofcmds) + macho.size,
                                                    length: Int(length + padding)))

        if occupant[0] != 0 {
            print("Cannot inject payload into \(dylibPath) because there is no room")
            return false
        }*/

        print("Inserting a \(LC(UInt32(LC_LOAD_DYLIB))) command for architecture: \(CPU(macho.header.cputype))")

        let dylib = dylib(name: lc_str(offset: UInt32(MemoryLayout.stride(ofValue: dylib_command.self))),
                          timestamp: 2,
                          current_version: 0,
                          compatibility_version: 0)
        var command = dylib_command(cmd: UInt32(LC_LOAD_DYLIB),
                                    cmdsize: UInt32(length + padding),
                                    dylib: dylib)

        var zeroByte: UInt = 0
        let commandData = NSMutableData(data: Data())
        commandData.append(&command, length: MemoryLayout.stride(ofValue: dylib_command.self))
        // commandData.append(dylibPath.data(using: .utf8)!)
        commandData.append(&zeroByte, length: Int(padding))

        binary.replaceBytes(in: NSRange(location: Int(macho.header.sizeofcmds) + macho.size,
                                        length: commandData.length), withBytes: nil, length: 0)

        /*binary.replaceBytes(in: NSRange(location: Int(lastOffset),
                                        length: 0), withBytes: commandData.bytes, length: commandData.length)*/

        // Increase the number of commands in the header by 1
        macho.header.ncmds += 1
        macho.header.sizeofcmds += command.cmdsize

        // Replace the old header with the new one
        binary.replaceBytes(in: NSRange(location: 0,
                                        length: MemoryLayout.size(ofValue: macho.header)), withBytes: &macho.header)

        return true
    }

    @discardableResult
    public static func removeLoadEntryFromBinary(_ binary: inout NSMutableData,
                                                 _ macho: inout thin_header,
                                                 _ payload: String) -> Bool {
        var offset: Int = macho.size

        var num: UInt32 = 0
        var cumulativeSize: UInt32 = 0
        var removedOrdinal: UInt32 = UInt32.max

        for index in 0..<macho.header.ncmds {
            if offset >= binary.length || offset > macho.size + Int(macho.header.sizeofcmds) {
                break
            }

            let cmdData = Data(bytes: binary[offset..<offset+4].base.bytes, count: 4)
            let cmd = cmdData.withUnsafeBytes { $0.load(as: UInt32.self) }

            let sizeData = Data(bytes: binary[offset+4..<offset+8].base
                .bytes, count: 4)
            let size = sizeData.withUnsafeBytes { $0.load(as: UInt32.self) }

            switch cmd {
            case LC_REEXPORT_DYLIB,
            LC_LOAD_UPWARD_DYLIB,
            LC_LOAD_WEAK_DYLIB,
            UInt32(LC_LOAD_DYLIB):
                let command: dylib_command = (binary.bytes + offset).load(as: dylib_command.self)
                let bytes = binary.subdata(with:
                                            NSRange(location: offset + Int(command.dylib.name.offset),
                                                    length: Int(command.cmdsize - command.dylib.name.offset)))
                    .withUnsafeBytes({ $0.load(as: Array<UInt8>.self) })
                let name = String(bytes: bytes, encoding: .utf8)
                if name == payload && removedOrdinal == UInt32.max {
                    print("Removing payload from \(LC(cmd))...")
                    binary.replaceBytes(in: NSRange(location: offset,
                                                    length: Int(size)), withBytes: nil, length: 0)
                    num += 1
                    cumulativeSize += size
                    removedOrdinal = index
                }

                offset += Int(size)
            default:
                offset += Int(size)
            }
        }

        if num == 0 {
            return false
        }

        macho.header.ncmds -= num
        macho.header.sizeofcmds -= cumulativeSize

        var zeroByte: UInt32 = 0
        binary.replaceBytes(in: NSRange(location: Int(macho.header.sizeofcmds) + macho.size,
                                        length: 0), withBytes: &zeroByte, length: Int(cumulativeSize))
        binary.replaceBytes(in: NSRange(location: 0,
                                        length: MemoryLayout.size(ofValue: macho.header)),
                            withBytes: &macho.header, length: MemoryLayout.size(ofValue: macho.header))

        return true
    }

    public static func binaryHasLoadCommandForDylib(_ binary: inout NSMutableData,
                                                    _ dylib: String,
                                                    _ lastOffset: inout UInt32,
                                                    _ macho: thin_header) -> Bool {
        var offset: Int = macho.size
        var loadOffset = offset

        for _ in 0..<macho.header.ncmds {
            if offset >= binary.length || offset > macho.size + Int(macho.header.sizeofcmds) {
                break
            }

            let cmdData = Data(bytes: binary[offset..<offset+4].base.bytes, count: 4)
            let cmd = cmdData.withUnsafeBytes { $0.load(as: UInt32.self) }

            let sizeData = Data(bytes: binary[offset+4..<offset+8].base.bytes, count: 4)
            let size = sizeData.withUnsafeBytes { $0.load(as: UInt32.self) }

            switch cmd {
            case LC_REEXPORT_DYLIB,
            LC_LOAD_UPWARD_DYLIB,
            LC_LOAD_WEAK_DYLIB,
            UInt32(LC_LOAD_DYLIB):
                let command: dylib_command = (binary.bytes + offset).load(as: dylib_command.self)
                let bytes = binary.subdata(with: NSRange(location: offset + Int(command.dylib.name.offset),
                                                         length: Int(command.cmdsize - command.dylib.name.offset)))
                    .withUnsafeBytes({ $0.load(as: Array<UInt8>.self) })
                let name = String(bytes: bytes, encoding: .utf8)

                if name == dylib {
                    lastOffset = UInt32(offset)
                    return true
                }

                offset += Int(size)
                loadOffset = offset
            default:
                offset += Int(size)
            }
        }

        lastOffset = UInt32(loadOffset)
        return false
    }

    public static func LC(_ loadCommand: UInt32) -> String {
        switch loadCommand {
        case LC_REEXPORT_DYLIB:
            return "LC_REEXPORT_DYLIB"
        case LC_LOAD_WEAK_DYLIB:
            return "LC_LOAD_WEAK_DYLIB"
        case LC_LOAD_UPWARD_DYLIB:
            return "LC_LOAD_UPWARD_DYLIB"
        case UInt32(LC_LOAD_DYLIB):
            return "LC_LOAD_DYLIB"
        default:
            return "\(loadCommand)"
        }
    }

    public static func CPU(_ cpuType: Int32) -> String {
        switch cpuType {
        case CPU_TYPE_I386:
            return "x86"
        case CPU_TYPE_X86_64:
            return "x86_64"
        case CPU_TYPE_ARM:
            return "arm"
        case CPU_TYPE_ARM64:
            return "arm64"
        default:
            return "\(cpuType)"
        }
    }
}
