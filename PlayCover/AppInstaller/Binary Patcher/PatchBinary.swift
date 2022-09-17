//
//  PatchBinary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 16/09/2022.
//

import Foundation

enum PatchError: Error {
    case noHeaderFound
    case failedToLoadBinary
}

extension PatchError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noHeaderFound:
            return "Could not find header!"
        case .failedToLoadBinary:
            return "Could not load binary!"
        }
    }
}

class PatchBinary {
    public static func patchBinaryWithDylib(binaryURL: URL, dylibName: String) throws {
        print(dylibName)

        guard var binary = NSMutableData(contentsOf: binaryURL) else { throw PatchError.failedToLoadBinary }
        var header = try Headers.headerFromBinary(binary: binary)

        if Operations.insertLoadEntryIntroBinary(dylibName, &binary, &header) {
            print("Successfully inserted a command for \(Operations.CPU(header.header.cputype))")
        } else {
            print("Failed to insert a command for \(Operations.CPU(header.header.cputype))")
        }

        try binary.write(to: binaryURL)
    }

    public static func removePlayToolsFrom(binaryURL: URL, dylibName: String) throws {
        guard var binary = NSMutableData(contentsOf: binaryURL) else { throw PatchError.failedToLoadBinary }
        var header = try Headers.headerFromBinary(binary: binary)

        Operations.removeLoadEntryFromBinary(&binary, &header, dylibName)

        try binary.write(to: binaryURL)
    }

}
