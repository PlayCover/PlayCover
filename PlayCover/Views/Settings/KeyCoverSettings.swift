//
//  KeyCoverSettings.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import SwiftUI

enum KeyCoverStatus: String, Codable, Hashable {
    case disabled
    case selfGeneratedPassword
    case userProvidedPassword
}

class KeyCoverPreferences: NSObject, ObservableObject {
    static var shared = KeyCoverPreferences()

    @AppStorage("keyCoverEnabled") var keyCoverEnabled: KeyCoverStatus = KeyCoverStatus.disabled
    @AppStorage("promptForKeyCoverPasswordAtLaunch") var promptForKeyCoverPasswordAtLaunch = true
}

struct KeyCoverSettings: View {
    static let shared = KeyCoverSettings()

    @State private var keyCoverInitialSetupShown = false
    @State private var keyCoverUpdatePasswordShown = false
    @State private var keyCoverRemovalViewShown = false

    @ObservedObject var keyCoverPreferences = KeyCoverPreferences.shared
    @ObservedObject var keyCoverObserved = KeyCoverObservable.shared

    @ObservedObject var modifierKeyObserver = ModifierKeyObserver.shared

    var body: some View {
        VStack {
            HStack {
                HStack {
                    Text("keycover.status.title")
                    Text(keyCoverObserved.keyCoverEnabled ?
                             KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword ?
                             "keycover.status.managedPassword" : "keycover.status.userPassword"
                         : "state.disabled")
                        .foregroundColor(keyCoverObserved.keyCoverEnabled ? .green : .none)
                    Spacer()
                }
                Spacer()
                Button(keyCoverObserved.keyCoverEnabled ? "button.Reset" : "button.Enable") {
                    if keyCoverObserved.keyCoverEnabled {
                        if modifierKeyObserver.isOptionKeyPressed {
                            KeyCoverPassword.shared.forceResetKeyCoverPassword()
                        } else {
                            keyCoverRemovalViewShown = true
                        }
                    } else {
                        keyCoverInitialSetupShown = true
                    }
                }
                .foregroundColor((keyCoverObserved.keyCoverEnabled
                                 && modifierKeyObserver.isOptionKeyPressed)
                                    ? .red : .none)
            }
            .padding()
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("keycover.status.chainCount")
                    Text(String(format: NSLocalizedString("keycover.status.unlockedCount %@ %@", comment: ""),
                                "\(keyCoverObserved.unlockedCount)",
                                "\(keyCoverObserved.keychains.count)"))
                }
                Spacer()
                Button("keycover.button.lockAll") {
                    KeyCover.shared.lockAllChainsAsync()
                }
                .disabled(!keyCoverObserved.keyCoverEnabled)
            }
            .padding()
            HStack {
                Spacer()
                Button("keycover.button.changePassword") {
                    keyCoverUpdatePasswordShown = true
                }
                .disabled(!keyCoverObserved.keyCoverEnabled)
                Spacer()
            }
            .padding()
            VStack(alignment: .leading) {
                Toggle("keycover.toggle.startupPrompt", isOn: $keyCoverPreferences.promptForKeyCoverPasswordAtLaunch)
                    .help("keycover.toggle.startupPrompt.help")
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
