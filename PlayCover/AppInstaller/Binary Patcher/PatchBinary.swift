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
            guard var binary = NSMutableData(contentsOf: binaryURL) else { return false }
            var headers = Headers.headersFromBinary(binary: binary)

            for index in 0..<headers.count {
                if Operations.insertLoadEntryIntroBinary(dylibName, &binary, &headers[index], UInt32(LC_LOAD_DYLIB)) {
                    print("Successfully inserted a command for \(headers[index].header.cputype)")
                } else {
                    print("Failed to insert a command for \(headers[index].header.cputype)")
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
            var headers = Headers.headersFromBinary(binary: binary)

            for index in 0...headers.count {
                Operations.removeLoadEntryFromBinary(&binary, &headers[index], dylibName)
            }

            try binary.write(to: binaryURL)
            return true
        } catch {
            Log.shared.error(error)
            return false
        }
    }

}
