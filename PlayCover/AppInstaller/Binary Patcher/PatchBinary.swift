//
//  PatchBinary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 16/09/2022.
//

import Foundation

class PatchBinary {
    public static func patchBinaryWithDylib(binaryURL: URL, dylibName: String) -> Bool {
        print(dylibName)

        do {
            guard let binary = NSMutableData(contentsOf: binaryURL) else { return false }
            let headers = Headers.headersFromBinary(binary: binary)

            for macho in headers {
                if Operations.insertLoadEntryIntroBinary(dylibName, binary, macho, UInt32(LC_LOAD_DYLIB)) {
                    print("Successfully inserted a command for \(macho.header.cputype)")
                } else {
                    print("Failed to insert a command for \(macho.header.cputype)")
                }
            }

            try binary.write(to: binaryURL)
            return true
        } catch {
            Log.shared.error(error)
            return false
        }
    }

    public static func removePlayToolsFrom(binaryURL: URL, dylibName: String) -> Bool {
        do {
            guard var binary = NSMutableData(contentsOf: binaryURL) else { return false }
            let headers = Headers.headersFromBinary(binary: binary)

            for macho in headers {
                Operations.removeLoadEntryFromBinary(&binary, macho, dylibName)
            }
            try binary.write(to: binaryURL)
            return true
        } catch {
            Log.shared.error(error)
            return false
        }
    }

}
