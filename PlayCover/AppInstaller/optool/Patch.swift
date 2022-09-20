//
//  Patch.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 20/09/2022.
//

import Foundation

class Patch {
    @discardableResult
    public static func patchBinaryWithDylib(binaryUrl: URL, dylibName: String) throws -> Bool {
        print(dylibName)

        var binary: OffsetNSData = OffsetNSData(offset: 0,
                                                data: try NSMutableData(contentsOf: binaryUrl))
        var headers: [thin_header] = Array(repeating: thin_header(), count: 4)
        var numHeaders: UInt32 = 0
        Headers.headersFromBinary(&headers, &binary, &numHeaders)

        for macho in headers {
            if Operations.insetLoadEntryIntoBinary(dylibName, &binary, macho) {
                print("Successfully inserted a command for \(cpu(macho.header.cputype))")
            } else {
                print("Failed to insert a command for \(cpu(macho.header.cputype))")
            }
        }

        try binary.data.write(to: binaryUrl)

        return true
    }

    public static func removePlayToolsFrom(binaryUrl: URL, dylibName: String) throws -> Bool {
        var binary: OffsetNSData = OffsetNSData(offset: 0,
                                                data: try NSMutableData(contentsOf: binaryUrl))

        var headers: [thin_header] = Array(repeating: thin_header(), count: 4)
        var numHeaders: UInt32 = 0
        Headers.headersFromBinary(&headers, &binary, &numHeaders)

        for macho in headers {
            Operations.removeLoadEntryFromBinary(&binary, macho, dylibName)
        }

        try binary.data.write(to: binaryUrl)

        return true
    }

    public static func cpu(_ cputype: cpu_type_t) -> String {
        if cputype == CPU_TYPE_I386 {
            return "x86"
        } else if cputype == CPU_TYPE_X86_64 {
            return "x86_64"
        } else if cputype == CPU_TYPE_ARM {
            return "arm"
        } else if cputype == CPU_TYPE_ARM64 {
            return "arm64"
        }
        return ""
    }

    public static func loadCommand(_ loadCommand: UInt32) -> String {
        if loadCommand == LC_REEXPORT_DYLIB {
            return "LC_REEXPORT_DYLIB"
        } else if loadCommand == LC_LOAD_WEAK_DYLIB {
            return "LC_LOAD_WEAK_DYLIB"
        } else if loadCommand == LC_LOAD_UPWARD_DYLIB {
            return "LC_LOAD_UPWARD_DYLIB"
        } else if loadCommand == LC_LOAD_DYLIB {
            return "LC_LOAD_DYLIB"
        }
        return ""
    }
}
