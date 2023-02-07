//
//  KeyCoverViews.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import Foundation
import SwiftUI

struct KeyCoverInitialSetupView: View {
    @Binding var isPresented: Bool

    @State private var masterKey = ""
    @State private var masterKeyConfirm = ""
    @State private var isEncrypting = false

    @State private var masterKeyError = false
    @State private var masterKeyConfirmError = false

    enum KeyOptions {
        case selfGeneratedPassword
        case userProvidedPassword
    }

    @State private var keyOption = KeyOptions.userProvidedPassword

    var body: some View {
        Picker("Encryption Key: ", selection: $keyOption) {
            Text("Managed Automatically")
                .tag(KeyOptions.selfGeneratedPassword)
            Text("Use my own key")
                .tag(KeyOptions.userProvidedPassword)
        }
        .pickerStyle(RadioGroupPickerStyle())
        .padding()
        .onChange(of: keyOption) { _ in
            switch keyOption {
            case .selfGeneratedPassword:
                masterKey = KeyCoverMaster.shared.generateMasterKey()
                masterKeyConfirm = masterKey
            case .userProvidedPassword:
                masterKey = ""
                masterKeyConfirm = ""
            }
        }

        VStack {
            Group {
                Text("Enter a master password to use for KeyCover")
                    .bold()
                SecureField("Master Password", text: $masterKey)
                SecureField("Confirm Master Password", text: $masterKeyConfirm)
                if masterKeyError {
                    Text("Password cannot be blank")
                        .foregroundColor(.red)
                        .padding()
                }
                if masterKeyConfirmError {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .disabled(keyOption != .userProvidedPassword)
            Divider()
            HStack {
                // Spinner to indicate that data is being encrypted
                if isEncrypting {
                    ProgressView()
                        .padding()
                        .progressViewStyle(.linear)
                }
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Continue") {
                    Task {
                        if masterKey == "" {
                            masterKeyError = true
                            return
                        }
                        if masterKey != masterKeyConfirm {
                            masterKeyConfirmError = true
                            return
                        }
                        Task(priority: .userInitiated) {
                            isEncrypting = true
                            switch keyOption {
                            case .userProvidedPassword:
                                KeyCoverPreferences.shared.keyCoverEnabled = .userProvidedPassword
                            case .selfGeneratedPassword:
                                KeyCoverPreferences.shared.keyCoverEnabled = .selfGeneratedPassword
                            }
                            KeyCoverMaster.shared.setMasterKey(masterKey)
                            isEncrypting = false
                            isPresented = false
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(isEncrypting)
        .padding()

    }
}

struct KeyCoverUpdatePasswordView: View {
    @Binding var isPresented: Bool

    @State private var oldMasterKey = KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword ?
                                        KeyCover.shared.keyCoverPlainTextKey ?? "" : ""
    @State private var masterKey = ""
    @State private var masterKeyConfirm = ""
    @State private var isWorking = false

    @State private var oldMasterKeyError = false
    @State private var masterKeyError = false
    @State private var masterKeyConfirmError = false

    enum KeyOptions {
        case selfGeneratedPassword
        case userProvidedPassword
    }

    @State private var keyOption = KeyOptions.userProvidedPassword

    var body: some View {
        VStack {
            Text("Enter your old master password and a new one to update your KeyCover encryption key")
                .bold()
            SecureField("Old Master Password", text: $oldMasterKey)
            .disabled(KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword)

            Picker("Encryption Key: ", selection: $keyOption) {
                Text("Managed Automatically")
                    .tag(KeyOptions.selfGeneratedPassword)
                Text("User-Provided Password")
                    .tag(KeyOptions.userProvidedPassword)
            }
            .pickerStyle(RadioGroupPickerStyle())
            .padding()
            .onChange(of: keyOption) { _ in
                switch keyOption {
                case .selfGeneratedPassword:
                    masterKey = KeyCoverMaster.shared.generateMasterKey()
                    masterKeyConfirm = masterKey
                case .userProvidedPassword:
                    masterKey = ""
                    masterKeyConfirm = ""
                }
            }

            Group {
                SecureField("New Master Password", text: $masterKey)
                SecureField("Confirm New Master Password", text: $masterKeyConfirm)
                if oldMasterKeyError {
                    Text("Incorrect password")
                        .foregroundColor(.red)
                        .padding()
                }
                if masterKeyError {
                    Text("Password is cannot be blank")
                        .foregroundColor(.red)
                        .padding()
                }
                if masterKeyConfirmError {
                    Text("Passwords do not match")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .disabled(keyOption != .userProvidedPassword)
            Divider()
            HStack {
                if isWorking {
                    ProgressView()
                        .padding()
                        .progressViewStyle(.linear)
                }
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Continue") {
                    Task {
                        if !KeyCoverMaster.shared.validateMasterKey(oldMasterKey) {
                            oldMasterKeyError = true
                            return
                        }
                        if masterKey == "" {
                            masterKeyError = true
                            return
                        }
                        if masterKey != masterKeyConfirm {
                            masterKeyConfirmError = true
                            return
                        }
                        Task(priority: .userInitiated) {
                            switch keyOption {
                            case .userProvidedPassword:
                                KeyCoverPreferences.shared.keyCoverEnabled = .userProvidedPassword
                            case .selfGeneratedPassword:
                                KeyCoverPreferences.shared.keyCoverEnabled = .selfGeneratedPassword
                            }
                            isWorking = true
                            Task(priority: .userInitiated) {
                                KeyCoverMaster.shared.setMasterKey(masterKey)
                            }
                            isWorking = false
                            isPresented = false
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(isWorking)
        .padding()
    }
}

struct KeyCoverRemovalView: View {
    @Binding var isPresented: Bool

    @State private var masterKey = KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword ?
                                    KeyCover.shared.keyCoverPlainTextKey ?? "" : ""
    @State private var isWorking = false

    @State private var masterKeyError = false

    enum KeyOptions {
        case selfGeneratedPassword
        case userProvidedPassword
    }

    @State private var keyOption = KeyOptions.selfGeneratedPassword

    var body: some View {
        VStack {
            Text("Enter your master password to remove KeyCover encryption")
                .bold()
            SecureField("Master Password", text: $masterKey)
            .disabled(KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword)
            if masterKeyError {
                Text("Incorrect password")
                    .foregroundColor(.red)
                    .padding()
            }
            Divider()
            HStack {
                if isWorking {
                    ProgressView()
                        .padding()
                        .progressViewStyle(.linear)
                }
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Continue") {
                    Task {
                        if !KeyCoverMaster.shared.validateMasterKey(masterKey) {
                            masterKeyError = true
                            return
                        }
                        Task(priority: .userInitiated) {
                            isWorking = true
                            KeyCoverMaster.shared.removeMasterKey()
                            isWorking = false
                            isPresented = false
                        }
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(isWorking)
        .padding()
    }
}
