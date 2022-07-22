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
        
        device?.setNominalSampleRate(48000.0)
        
        Log.shared.error("No device with sample rate of 48 or 44.1 KHz was found! PlayCover will attempt to set your current output device's sample rate to 48 KHz. Check Audio MIDI Settings if crashes occur!")
    }
}
