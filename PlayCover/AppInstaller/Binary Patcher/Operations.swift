//
//  Operations.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 16/09/2022.
//

import Foundation

class Operations {
    public static func insertLoadEntryIntroBinary(_ dylibPath: String, _ binary: NSMutableData, _ macho: inout thin_header, _ type: inout UInt32) -> Bool {
        if type != LC_REEXPORT_DYLIB &&
            type != LC_LOAD_WEAK_DYLIB &&
            type != LC_LOAD_UPWARD_DYLIB &&
            type != LC_LOAD_DYLIB {
            print("Invalid load command type")
            return false
        }
        
        var lastOffset: UInt32 = 0
        if (binaryHasLoadCommandForDylib(binary, dylibPath, &lastOffset, macho)) {
            var originalType: UInt32 = (binary.bytes + Int(lastOffset)).load(as: UInt32.self)
            if originalType != type {
                print("A load command already exists for \(dylibPath). Changing command type from \(LC(originalType)) to desired \(LC(type))")
                binary.replaceBytes(in: NSMakeRange(Int(lastOffset), MemoryLayout.size(ofValue: type)), withBytes: &type)
            } else {
                print("Load command already exists")
            }
        }

        let length: UInt = UInt(MemoryLayout.size(ofValue: dylib_command.self)) + UInt(dylibPath.count)
        let padding: UInt = (8 - (length % 8))
        
        let occupant = binary.subdata(with: NSMakeRange(Int(macho.header.sizeofcmds + macho.offset + macho.size), Int(length + padding)))
        
        occupant.withUnsafeBytes({ bytes in
            if (strcmp(bytes.load(as: CChar?.self), "\0") != 0) {
                Log("Cannot inject payload into \(dylibPath) because there is no room")
                return false
            }
        })
        
        print("Inserting a \(LC(type)) command for architecture: \(macho.header.cputype)")
        
        let command: dylib_command
        let dylib: MachO.dylib
        dylib.name.offset = UInt32(MemoryLayout.size(ofValue: dylib_command.self))
        dylib.timestamp = 2
        dylib.current_version = 0
        dylib.compatibility_version = 0
        command.cmd = type
        command.dylib = dylib
        command.cmdsize = UInt32(length + padding)
        
        let zeroByte: UInt = 0
        var commandData = NSMutableData(data: Data())
        commandData.append(command, length: MemoryLayout.size(ofValue: dylib_command.self))
        commandData.append(dylibPath.data(using: .ascii)!)
        commandData.append(zeroByte, length: Int(padding))
        
        binary.replaceBytes(in: NSMakeRange(Int(macho.offset + macho.header.sizeofcmds + macho.size), commandData.length), withBytes: nil, length: 0)
        
        binary.replaceBytes(in: NSMakeRange(Int(lastOffset), 0), withBytes: commandData.bytes, length: commandData.length)
        
        macho.header.ncmds += 1
        macho.header.sizeofcmds += command.cmdsize
        
        binary.replaceBytes(in: NSMakeRange(Int(macho.offset), MemoryLayout.size(ofValue: macho.header)), withBytes: &macho.header)
        
        return true
    }
    
    public static func removeLoadEntryFromBinary(_ binary: inout NSMutableData, _ macho: inout thin_header, _ payload: String) -> Bool {
        var offset: Int = Int(macho.offset + macho.size)
        
        var num: UInt32 = 0
        var cumulativeSize: UInt32 = 0
        var removedOrdinal: UInt32 = -1
        
        for index in 0...macho.header.ncmds {
            if offset >= binary.length || offset > macho.offset + macho.size + macho.header.sizeofcmds {
                break
            }
            
            let cmd: UInt32 = binary[offset]
            let size: UInt32 = binary.intAtOffset(atOffset: binary.currentOffset() + 4)
            
            switch cmd {
            case LC_REEXPORT_DYLIB,
            LC_LOAD_UPWARD_DYLIB,
            LC_LOAD_WEAK_DYLIB,
            UInt32(LC_LOAD_DYLIB):
                var command: dylib_command = (binary.bytes + offset).load(as: dylib_command.self)
                let name = binary.subdata(with: NSMakeRange(offset + command.dylib.name.offset), Int(command.cmdsize - command.dylib.name.offset))).base64EncodedString()
                if name == payload && removedOrdinal == -1 {
                    print("Removing payload from \(LC(cmd))...")
                    binary.replaceBytes(in: NSMakeRange(offset, Int(size)), withBytes: nil, length: 0)
                    num += 1
                    cumulativeSize += size
                    removedOrdinal = index
                }
                
                offset += Int(size)
                break
            default:
                offset += Int(size)
                break
            }
        }
        
        if num == 0 {
            return false
        }
        
        macho.header.ncmds -= num
        macho.header.sizeofcmds -= cumulativeSize
        
        var zeroByte: UInt32 = 0
        binary.replaceBytes(in: NSMakeRange(Int(macho.offset + macho.header.sizeofcmds + macho.size), 0), withBytes: &zeroByte, length: Int(cumulativeSize))
        binary.replaceBytes(in: NSMakeRange(Int(macho.offset), MemoryLayout.size(ofValue: macho.header)), withBytes: &macho.header, length: MemoryLayout.size(ofValue: macho.header))
        
        return true
    }
    
    public static func binaryHasLoadCommandForDylib(_ binary: inout NSMutableData, _ dylib: inout String, _ lastOffset: inout UInt32, _ macho: thin_header) -> Bool {
        var offset: Int = Int(macho.size + macho.offset)
        var loadOffset = offset
        
        for _ in 0...macho.header.ncmds {
            if offset >= binary.length || offset > macho.offset + macho.size + macho.header.sizeofcmds {
                break
            }
            
            let cmd: UInt32 = binary.int(atOffset: offset)
            let size: UInt32 = binary.int(atOffset: offset + 4)
            
            switch cmd {
            case LC_REEXPORT_DYLIB,
            LC_LOAD_UPWARD_DYLIB,
            LC_LOAD_WEAK_DYLIB,
            UInt32(LC_LOAD_DYLIB):
                let command: dylib_command = (binary.bytes + offset).load(as: dylib_command.self)
                let name = binary.subdata(with: NSMakeRange(offset + Int(command.dylib.name.offset), Int(command.cmdsize - command.dylib.name.offset))).base64EncodedString()
                
                if name == dylib {
                    lastOffset = offset
                    return true
                }
                
                offset += Int(size)
                loadOffset = offset
                break
            default:
                offset += size
                break
            }
        }
        
        if lastOffset != nil {
            lastOffset = loadOffset
        }
        
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
        case LC_LOAD_DYLIB:
            return "LC_LOAD_DYLIB"
        default:
            return ""
        }
    }
}
