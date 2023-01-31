//
//  KeyCoverSettings.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import SwiftUI

class KeyCoverPreferences: NSObject, ObservableObject {
    static var shared = KeyCoverPreferences()

    @AppStorage("promptForMasterPasswordAtLaunch") var promptForMasterPasswordAtLaunch = true
    @AppStorage("keyCoverSmartLock") var keyCoverSmartLock = true
    @AppStorage("keyCoverSmartLockTimeout") var keyCoverSmartLockTimeout = 5
    @AppStorage("keyCoverSmartUnlock") var keyCoverSmartUnlock = true
}

struct KeyCoverSettings: View {
    static let shared = KeyCoverSettings()

    @State private var keyCoverStatus = KeyCover.shared.isKeyCoverEnabled

    @State private var keyCoverInitialSetupShown = false
    @State private var keyCoverUpdatePasswordShown = false
    @State private var keyCoverRemovalViewShown = false

    @ObservedObject var keyCoverPreferences = KeyCoverPreferences.shared

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("KeyCover Status:")
                    Text(keyCoverStatus ? "Enabled" : "Disabled")
                        .foregroundColor(keyCoverStatus ? .green : .none)
                    Spacer()
                }
                Spacer()
                Button(keyCoverStatus ? "Reset" : "Enable") {
                    if keyCoverStatus {
                        KeyCoverRemovalView.openWindow()
                    } else {
                        KeyCoverInitialSetupView.openWindow()
                    }
                }
                .foregroundColor(keyCoverStatus ? .red : .none)
            }
            .padding()
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("KeyCover Chain Status:")
                    Text("\(KeyCover.shared.unlockedCount)"
                         + "unlocked chains in \(KeyCover.shared.keychains.count) chains total")
                }
                Spacer()
                Button("Lock All Chains Now") {
                    KeyCover.shared.lockAllChainsAsync()
                }
                .disabled(!keyCoverStatus)
            }
            .padding()
            HStack {
                Spacer()
                Button("Change Master Password") {
                    KeyCoverUpdatePasswordView.openWindow()
                }
                .disabled(!keyCoverStatus)
                Spacer()
            }
            .padding()
            VStack(alignment: .leading) {
                Toggle("Prompt for KeyCover at startup", isOn: $keyCoverPreferences.promptForMasterPasswordAtLaunch)
                    .help("KeyCover will prompt for your master password when you launch the application")
                HStack {
                    Toggle("KeyCover Smart Lock", isOn: $keyCoverPreferences.keyCoverSmartLock)
                    .help("KeyCover will automatically lock your keychains when you quit the associated application")
                    Spacer()
                    Stepper("Timeout: \(keyCoverPreferences.keyCoverSmartLockTimeout) seconds",
                            value: $keyCoverPreferences.keyCoverSmartLockTimeout, in: 1...60)
                }
                Toggle("KeyCover Smart Unlock", isOn: $keyCoverPreferences.keyCoverSmartUnlock)
                .help("KeyCover will automatically unlock your keychains when the associated application is launched")
            }
            .padding()
        }
        .frame(width: 500, height: 300)
    }
}

struct KeyCoverSettings_Previews: PreviewProvider {
    static var previews: some View {
        KeyCoverSettings()
    }
}
