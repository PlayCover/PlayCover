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
    var size: Int = 0
    var header: mach_header_64 = mach_header_64()
}

class Headers {
    public static func headerFromBinary(binary: NSData) throws -> thin_header {
        // First four bytes contain 'magic' value
        let magicData = Data(bytes: binary[0..<4].base.bytes, count: 4)
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }

        // We only need to look for 64-bit headers
        if magic == MH_MAGIC_64 {
            let macho = headerAtOffset(binary)
            if macho.size > 0 {
                print("Found header...")
                return macho
            } else {
                print("Found empty header!")
                throw PatchError.headerEmpty
            }
        } else {
            print("Header of wrong type!")
        }

        print("No header found!")
        throw PatchError.noHeaderFound
    }

    public static func headerAtOffset(_ binary: NSData) -> thin_header {
        let header = binary.bytes.load(as: mach_header_64.self)
        var size = MemoryLayout.stride(ofValue: mach_header_64.self)

        // If the header is not for a 64-bit ARM CPU, it should be ignored
        if header.cputype != CPU_TYPE_ARM64 {
            size = 0
        }
        return thin_header(size: size, header: header)
    }
}
