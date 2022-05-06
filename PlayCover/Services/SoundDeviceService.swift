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
        
        var found = false
        
        if let sampleRate = device?.nominalSampleRate {
            if sampleRate == 48000.0 || sampleRate == 44100.0 {
                found = true
                return
            }
        }
        
        for device in simplyCA.allOutputDevices {
            if let sampleRate = device.nominalSampleRate {
                if sampleRate == 48000.0 || sampleRate == 44100.0 {
                    device.isDefaultOutputDevice = true
                    found = true
                    break
                }
            }
        }
        if !found {
            Log.shared.msg("No device with sample rate of 48 / 44.1 ghz found! Please, lower sample rate in Audio settings or connect another output audio device. Otherwise crashes possible!")
        }
    }
}
