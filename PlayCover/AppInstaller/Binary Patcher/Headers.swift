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
    public static func headersFromBinary(binary: NSData) -> [thin_header] {
        var headers: [thin_header] = []
        let magicData = Data(bytes: binary[0..<4].base.bytes, count: 4)
        let magic = magicData.withUnsafeBytes { $0.load(as: UInt32.self) }
        let shouldSwap = magic == MH_CIGAM || magic == MH_CIGAM_64 || magic == FAT_CIGAM
        var numArchs: Int = 0

        if magic == FAT_CIGAM || magic == FAT_MAGIC {
            print("Found FAT Header")

            var fat = binary.bytes.load(as: fat_header.self)
            fat.nfat_arch = swap(shouldSwap, fat.nfat_arch)
            var offset = MemoryLayout.size(ofValue: fat_header.self)

            for _ in 0..<fat.nfat_arch {
                var arch = fat_arch()
                arch = (binary.bytes + offset).load(as: fat_arch.self)
                arch.cputype = cpu_type_t(swap(shouldSwap, arch.cputype))
                arch.offset = swap(shouldSwap, arch.offset)

                let macho = headerAtOffset(binary, arch.offset)
                if macho.size > 0 {
                    print("Found thin header...")
                    headers[numArchs] = macho
                    numArchs += 1
                }

                offset += MemoryLayout.size(ofValue: fat_arch.self)
            }
        } else if magic == MH_MAGIC || magic == MH_MAGIC_64 {
            let macho = headerAtOffset(binary, 0)
            if macho.size > 0 {
                print("Found thin header...")
                numArchs += 1
                headers[0] = macho
            }
        } else {
            print("No headers found.")
        }

        return headers
    }

    private static func swap(_ bool: Bool, _ int: Int32) -> Int32 {
        return bool ? Int32(CFSwapInt32(UInt32(int))) : int
    }

    private static func swap(_ bool: Bool, _ int: UInt32) -> UInt32 {
        return bool ? CFSwapInt32(int) : int
    }

    public static func headerAtOffset(_ binary: NSData, _ offset: UInt32) -> thin_header {
        let header = (binary.bytes + Int(offset)).load(as: mach_header.self)
        var size: UInt32 = 0

        if header.magic == MH_MAGIC || header.magic == MH_CIGAM {
            size = UInt32(MemoryLayout.size(ofValue: mach_header.self))
        } else {
            size = UInt32(MemoryLayout.size(ofValue: mach_header_64.self))
        }

        if header.cputype != CPU_TYPE_X86_64 &&
           header.cputype != CPU_TYPE_I386 &&
           header.cputype != CPU_TYPE_ARM &&
           header.cputype != CPU_TYPE_ARM64 {
            size = 0
        }
        return thin_header(offset: offset, size: size, header: header)
    }
}
