//
//  OffsetNSData.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 20/09/2022.
//

import Foundation

class OffsetNSData {
    var offset: Int
    var data: NSMutableData

    func intAtOffset(offset: Int) -> UInt32 {
        var result: UInt32 = 0
        data.getBytes(&result,
                      range: NSRange(location: offset,
                                              length: MemoryLayout.size(ofValue: result)))
        return result
    }

    init(offset: Int, data: NSMutableData) {
        self.offset = offset
        self.data = data
    }
}
