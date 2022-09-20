//
//  Headers.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 20/09/2022.
//

import Foundation

// swiftlint:disable type_name
public struct thin_header {
    var offset: UInt32 = 0
    var size: UInt32 = 0
    var header: mach_header = mach_header()
}

class Headers {
    public static func headerAtOffset(binary: inout OffsetNSData, offset: UInt32) -> thin_header {
        var macho = thin_header()
        macho.offset = offset
        macho.header = (binary.data.bytes + Int(offset)).load(as: mach_header.self)
        macho.size = UInt32(MemoryLayout.stride(ofValue: mach_header_64.self))

        if macho.header.cputype != CPU_TYPE_ARM64 {
            macho.size = 0
        }

        return macho
    }

    public static func headersFromBinary(_ headers: inout [thin_header],
                                         _ binary: inout OffsetNSData,
                                         _ amount: inout UInt32) {
        let magic: UInt32 = binary.intAtOffset(offset: 0)
        var numArchs: UInt32 = 0

        if magic == MH_MAGIC_64 {
            let macho = headerAtOffset(binary: &binary, offset: 0)
            if macho.size > 0 {
                print("Found thin header...")

                numArchs += 1
                headers[0] = macho
            }
        } else {
            print("No headers found.")
        }

        amount = numArchs
    }
}
