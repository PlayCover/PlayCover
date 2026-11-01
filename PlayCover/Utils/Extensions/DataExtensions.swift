//
//  DataExtensions.swift
//  PlayCover
//

import Foundation

// swiftlint:disable force_unwrapping
extension String {
    nonisolated init(data: Data, offset: Int, commandSize: Int, loadCommandString: lc_str) {
        let loadCommandStringOffset = Int(loadCommandString.offset)
        let stringOffset = offset + loadCommandStringOffset
        let length = commandSize - loadCommandStringOffset
        let rawData = data[stringOffset..<(stringOffset + length)]
        let endIndex = rawData.firstIndex(of: 0x00) ?? rawData.endIndex
        self = String(data: data[stringOffset..<endIndex], encoding: .utf8)!
    }
}

extension Data {
    nonisolated func extract<T>(_ type: T.Type, offset: Int = 0) -> T {
        let data = self[offset..<offset + MemoryLayout<T>.size]
        return data.withUnsafeBytes { dataBytes in
            dataBytes.baseAddress!
                .assumingMemoryBound(to: UInt8.self)
                .withMemoryRebound(to: T.self, capacity: 1) { (pointer) -> T in
                return pointer.pointee
            }
        }
    }

    nonisolated func extract<T: MachOByteSwappable>(_ type: T.Type, offset: Int = 0, swapped: Bool) -> T {
        let value = extract(type, offset: offset)
        return swapped ? value.byteSwapped : value
    }
}
// swiftlint:enable force_unwrapping
