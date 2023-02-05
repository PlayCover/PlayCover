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
    @AppStorage("keyCoverSmartUnlock") var keyCoverSmartUnlock = true
}

struct KeyCoverSettings: View {
    static let shared = KeyCoverSettings()

    @State private var keyCoverInitialSetupShown = false
    @State private var keyCoverUpdatePasswordShown = false
    @State private var keyCoverRemovalViewShown = false

    @ObservedObject var keyCoverPreferences = KeyCoverPreferences.shared
    @ObservedObject var keyCoverObserved = KeyCoverObservable.shared

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("KeyCover Status:")
                    Text(keyCoverObserved.keyCoverEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(keyCoverObserved.keyCoverEnabled ? .green : .none)
                    Spacer()
                }
                Spacer()
                Button(keyCoverObserved.keyCoverEnabled ? "Reset" : "Enable") {
                    if keyCoverObserved.keyCoverEnabled {
                        keyCoverRemovalViewShown = true
                    } else {
                        keyCoverInitialSetupShown = true
                    }
                }
                .foregroundColor(keyCoverObserved.keyCoverEnabled ? .red : .none)
            }
            .padding()
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("KeyCover Chain Status:")
                    Text("\(keyCoverObserved.unlockedCount) "
                         + "unlocked chains in \(keyCoverObserved.keychains.count) chains total")
                }
                Spacer()
                Button("Lock All Chains Now") {
                    KeyCover.shared.lockAllChainsAsync()
                }
                .disabled(!keyCoverObserved.keyCoverEnabled)
            }
            .padding()
            HStack {
                Spacer()
                Button("Change Master Password") {
                    keyCoverUpdatePasswordShown = true
                }
                .disabled(!keyCoverObserved.keyCoverEnabled)
                Spacer()
            }
            .padding()
            VStack(alignment: .leading) {
                Toggle("Prompt for KeyCover at startup", isOn: $keyCoverPreferences.promptForMasterPasswordAtLaunch)
                    .help("""
                            KeyCover will prompt for your master password when you launch the application.
                            If this is disabled, it will be prompted when you launch an app that uses PlayChain.
                            """)
                Toggle("KeyCover Smart Lock", isOn: $keyCoverPreferences.keyCoverSmartLock)
                .help("KeyCover will automatically lock your keychains when you quit the associated application")
                Toggle("KeyCover Smart Unlock", isOn: $keyCoverPreferences.keyCoverSmartUnlock)
                .help("KeyCover will automatically unlock your keychains when the associated application is launched")
                Spacer()
            }
            .padding()
        }
        .frame(width: 500, height: 300)
        .sheet(isPresented: $keyCoverInitialSetupShown) {
            KeyCoverInitialSetupView(isPresented: $keyCoverInitialSetupShown)
        }
        .sheet(isPresented: $keyCoverUpdatePasswordShown) {
            KeyCoverUpdatePasswordView(isPresented: $keyCoverUpdatePasswordShown)
        }
        .sheet(isPresented: $keyCoverRemovalViewShown) {
            KeyCoverRemovalView(isPresented: $keyCoverRemovalViewShown)
        }
    }
}

struct KeyCoverSettings_Previews: PreviewProvider {
    static var previews: some View {
        KeyCoverSettings()
    }
}
