//
//  SoundDeviceService.swift
//  PlayCover
//

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
            alert.messageText = NSLocalizedString("soundAlert.messageText", comment: "")
            alert.informativeText = NSLocalizedString("soundAlert.informativeText", comment: "")
            alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))
            alert.alertStyle = .critical
            let response: NSApplication.ModalResponse = alert.runModal()
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                device?.setNominalSampleRate(48000.0)
                Log.shared.msg(NSLocalizedString("soundAlert.successText", comment: ""))
            }
        }
    }
}
