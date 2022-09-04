//
//  SoundDeviceService.swift
//  PlayCover
//

import CoreAudio
import SwiftUI

class SoundDeviceService {

    static let shared = SoundDeviceService()

    private init() { }

    private func getAudioPropertyAddress(
        selector: AudioObjectPropertySelector
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain)
    }

    private func getAudioPropertyData<T>(
        _ objectID: AudioObjectID,
        address: inout AudioObjectPropertyAddress,
        result: inout T
    ) -> OSStatus {
        var size = UInt32(MemoryLayout<T>.size)
        return AudioObjectGetPropertyData(objectID, &address, UInt32(0), nil, &size, &result)
    }

    private func setAudioPropertyData<T>(
        _ objectID: AudioObjectID,
        address: inout AudioObjectPropertyAddress,
        value: inout T)
    -> OSStatus {
        let size = UInt32(MemoryLayout<T>.size)
        return AudioObjectSetPropertyData(objectID, &address, UInt32(0), nil, size, &value)
    }

    private func getSoundDevice() -> AudioDeviceID? {
        var address = getAudioPropertyAddress(selector: kAudioHardwarePropertyDefaultOutputDevice)
        var deviceID = AudioDeviceID()
        let objectID = AudioObjectID(kAudioObjectSystemObject)
        if getAudioPropertyData(objectID, address: &address, result: &deviceID) != noErr {
            return nil
        } else {
            return deviceID
        }
    }

    private func getSampleRate(_ deviceID: AudioObjectID) -> Float64? {
        var result = Float64(0.0)
        var address = getAudioPropertyAddress(selector: kAudioDevicePropertyNominalSampleRate)
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        if getAudioPropertyData(deviceID, address: &address, result: &result) != noErr {
            return nil
        } else {
            return result
        }
    }

    private func setSampleRate(_ deviceID: AudioObjectID, sampleRate: Float64) -> OSStatus {
        var value = sampleRate
        var address = getAudioPropertyAddress(selector: kAudioDevicePropertyNominalSampleRate)
        return setAudioPropertyData(deviceID, address: &address, value: &value)
    }

    func prepareSoundDevice() {
        guard let device = getSoundDevice() else { return }
        if let sampleRate = getSampleRate(device) {
            if sampleRate == 48000.0 || sampleRate == 44100.0 { return }
        }
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("soundAlert.messageText", comment: "")
            alert.informativeText = NSLocalizedString("soundAlert.informativeText", comment: "")
            alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))
            alert.alertStyle = .critical
            let response: NSApplication.ModalResponse = alert.runModal()
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                if self.setSampleRate(device, sampleRate: 48000) == noErr {
                    Log.shared.msg(NSLocalizedString("soundAlert.successText", comment: ""))
                } else {
                    Log.shared.error(NSLocalizedString("soundAlert.failureText", comment: ""))
                }
            }
        }
    }
}
