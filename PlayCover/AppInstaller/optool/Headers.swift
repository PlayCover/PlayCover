//
//  Headers.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 16/09/2022.
//

import Foundation
import MachO

class Headers {
    public static func headersFromBinary(binary: NSData) -> [thin_header] {
        var headers = Array(repeating: thin_header(), count: 4)
        let magic: UInt32 = binary.int(atOffset: 0)
        let shouldSwap = magic == MH_CIGAM || magic == MH_CIGAM_64 || magic == FAT_CIGAM
        var numArchs: Int = 0

        if magic == FAT_CIGAM || magic == FAT_MAGIC {
            print("Found FAT Header")

            var fat = binary.bytes.load(as: fat_header.self)
            fat.nfat_arch = swap(shouldSwap, fat.nfat_arch)
            var offset = MemoryLayout.size(ofValue: fat_header.self)

            for _ in 0...fat.nfat_arch {
                var arch = fat_arch()
                arch = (binary.bytes + offset).load(as: fat_arch.self)
                arch.cputype = cpu_type_t(swap(shouldSwap, arch.cputype))
                arch.offset = swap(shouldSwap, arch.offset)

                let macho = headerAtOffset(binary as Data, arch.offset)
                if macho.size > 0 {
                    print("Found thin header...")
                    headers[numArchs] = macho
                    numArchs += 1
                }

                offset += MemoryLayout.size(ofValue: fat_arch.self)
            }
        } else if magic == MH_MAGIC || magic == MH_MAGIC_64 {
            let macho = headerAtOffset(binary as Data, 0)
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

    /*public static func headerAtOffsetSwift(_ binary: NSData, _ offset: Int) -> thin_header {
        var macho = thin_header()
        macho.offset = UInt32(offset)
        macho.header = (binary.bytes + offset).load(as: mach_header.self)

        if macho.header.magic == MH_MAGIC || macho.header.magic == MH_CIGAM {
            macho.size = UInt32(MemoryLayout.size(ofValue: mach_header.self))
        } else {
            macho.size = UInt32(MemoryLayout.size(ofValue: mach_header_64.self))
        }

        if macho.header.cputype != CPU_TYPE_X86_64 &&
            macho.header.cputype != CPU_TYPE_I386 &&
            macho.header.cputype != CPU_TYPE_ARM &&
            macho.header.cputype != CPU_TYPE_ARM64 {
            macho.size = 0
        }
        return macho
    }*/
}
