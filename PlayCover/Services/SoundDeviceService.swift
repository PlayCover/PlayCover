//
//  SoundDeviceService.swift
//  PlayCover
//

import Foundation
import SimplyCoreAudio
import SwiftUI

class SoundDeviceService {

    static let shared = SoundDeviceService()

    private init() { }

    func prepareSoundDevice() {
        let simplyCA = SimplyCoreAudio()

        let device = simplyCA.defaultOutputDevice

        if let sampleRate = device?.nominalSampleRate {
            if sampleRate == 48000.0 || sampleRate == 44100.0 { return }
        }
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Incorrect Audio Settings Detected!"
            alert.informativeText = "Your current output device does not have a sample rate of 48 or 44.1 KHz!" +
                "Crashes may occur. Would you like to change your current output device's sample rate to 48 KHz?"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .critical
            let response: NSApplication.ModalResponse = alert.runModal()
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                device?.setNominalSampleRate(48000.0)
                Log.shared.msg("Current output device sample rate set to 48 KHz")
            }
        }
        
    }
}
