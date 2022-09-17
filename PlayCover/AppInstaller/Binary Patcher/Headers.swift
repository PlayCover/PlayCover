//
//  Headers.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 16/09/2022.
//

import Foundation
import MachO

// swiftlint:disable type_name
struct thin_header {
    var offset: UInt32 = 0
    var size: UInt32 = 0
    var header: mach_header = mach_header()
}

class Headers {
    public static func headerFromBinary(binary: NSData) throws -> thin_header {
        // First four bytes contain 'magic' value
        let magicData = Data(bytes: binary[0..<4].base.bytes, count: 4)
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }

        // We only need to look for 64-bit headers
        if magic == MH_MAGIC_64 {
            let macho = headerAtOffset(binary, 0)
            if macho.size > 0 {
                print("Found header...")
                return macho
            }
        }
        print("No header found!")
        throw PatchError.noHeaderFound
    }

    public static func headerAtOffset(_ binary: NSData, _ offset: UInt32) -> thin_header {
        let header = (binary.bytes + Int(offset)).load(as: mach_header.self)
        var size: UInt32 = 0

        size = UInt32(MemoryLayout.size(ofValue: mach_header_64.self))

        // If the header is not for a 64-bit ARM CPU, it should be ignored
        if header.cputype != CPU_TYPE_ARM64 {
            size = 0
        }
        return thin_header(offset: offset, size: size, header: header)
    }
}
