//
//  ProcessExtension.swift
//  PlayCover
//

import Foundation

extension ProcessInfo {

    func isMonterey() -> Bool {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return osVersion.majorVersion >= 12
    }

    func isM1() -> Bool {
        var ret = Int32(0)
        var size = MemoryLayout.size(ofValue: ret)
        let result = sysctlbyname("sysctl.proc_translated", &ret, &size, nil, 0)
        if result == -1 {
            if errno == ENOENT {
                return false
            }
            return false
        }
        // Rosetta translated
        return ret == Int32(1)
    }

}
