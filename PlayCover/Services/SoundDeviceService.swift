//
//  SoundDeviceService.swift
//  PlayCover
//

import Foundation
import SimplyCoreAudio

class SoundDeviceService {

    static let shared = SoundDeviceService()

    private init() { }

    func prepareSoundDevice() {
        let simplyCA = SimplyCoreAudio()

        let device = simplyCA.defaultOutputDevice

        if let sampleRate = device?.nominalSampleRate {
            if sampleRate == 48000.0 || sampleRate == 44100.0 { return }
        }

        for device in simplyCA.allOutputDevices {
            if let sampleRate = device.nominalSampleRate {
                if sampleRate == 48000.0 || sampleRate == 44100.0 {
                    device.isDefaultOutputDevice = true
                    return
                }
            }
        }

        Log.shared.msg("No device with sample rate of 48 / 44.1 ghz found! " +
                       "Please lower sample rate in Audio settings or connect another output audio device." +
                       " Otherwise crashes are possible!")
    }
}
