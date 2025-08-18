//
//  PlayInformation.swift
//  PlayTools
//

import Foundation

class PlayInfo {
    static var isLauncherInstalled: Bool {
        return AKInterface.shared!
            .urlForApplicationWithBundleIdentifier("io.playcover.PlayCover") != nil
    }
}

extension ProcessInfo {
    @objc open var isMacCatalystApp: Bool {
        return false
    }
    @objc open var isiOSAppOnMac: Bool {
        return true
    }
    @objc open var thermalState: ProcessInfo.ThermalState {
        return ProcessInfo.ThermalState.nominal
    }
    @objc open var isLowPowerModeEnabled: Bool {
        return false
    }
}
