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

@Observable
final class KeyCoverPreferences {
    static var shared: KeyCoverPreferences { AppEnvironment.shared.keyCoverPreferences }

    private enum Keys {
        static let keyCoverEnabled = "keyCoverEnabled"
        static let promptAtLaunch = "promptForKeyCoverPasswordAtLaunch"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var keyCoverEnabled: KeyCoverStatus {
        didSet { defaults.set(keyCoverEnabled.rawValue, forKey: Keys.keyCoverEnabled) }
    }
    var promptForKeyCoverPasswordAtLaunch: Bool {
        didSet { defaults.set(promptForKeyCoverPasswordAtLaunch, forKey: Keys.promptAtLaunch) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Keys.promptAtLaunch: true])
        keyCoverEnabled = defaults.string(forKey: Keys.keyCoverEnabled).flatMap(KeyCoverStatus.init) ?? .disabled
        promptForKeyCoverPasswordAtLaunch = defaults.bool(forKey: Keys.promptAtLaunch)
    }
}

struct KeyCoverSettings: View {
    @State private var keyCoverInitialSetupShown = false
    @State private var keyCoverUpdatePasswordShown = false
    @State private var keyCoverRemovalViewShown = false

    @Environment(KeyCoverPreferences.self) private var keyCoverPreferences
    @Environment(KeyCoverService.self) private var keyCover
    @Environment(ModifierKeyObserver.self) private var modifierKeyObserver

    var body: some View {
        @Bindable var keyCoverPreferences = keyCoverPreferences
        VStack {
            HStack {
                HStack {
                    Text("keycover.status.title")
                    Text(keyCover.isEnabled ?
                             keyCoverPreferences.keyCoverEnabled == .selfGeneratedPassword ?
                             "keycover.status.managedPassword" : "keycover.status.userPassword"
                         : "state.disabled")
                        .foregroundColor(keyCover.isEnabled ? .green : .none)
                    Spacer()
                }
                Spacer()
                Button(keyCover.isEnabled ? "button.Reset" : "button.Enable") {
                    if keyCover.isEnabled {
                        if modifierKeyObserver.isOptionKeyPressed {
                            keyCover.forceResetPassword()
                        } else {
                            keyCoverRemovalViewShown = true
                        }
                    } else {
                        keyCoverInitialSetupShown = true
                    }
                }
                .foregroundColor((keyCover.isEnabled && modifierKeyObserver.isOptionKeyPressed) ? .red : .none)
            }
            .padding()
            Spacer()
            HStack {
                VStack(alignment: .leading) {
                    Text("keycover.status.chainCount")
                    Text(String(format: NSLocalizedString("keycover.status.unlockedCount %@ %@", comment: ""),
                                "\(keyCover.unlockedCount)",
                                "\(keyCover.keychains.count)"))
                }
                Spacer()
                Button("keycover.button.lockAll") {
                    Task { await keyCover.lockAllChains() }
                }
                .disabled(!keyCover.isEnabled)
            }
            .padding()
            HStack {
                Spacer()
                Button("keycover.button.changePassword") {
                    keyCoverUpdatePasswordShown = true
                }
                .disabled(!keyCover.isEnabled)
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
        .frame(width: 600, height: 300)
        .onAppear { keyCover.refresh() }
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
