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

    @State private var keyOption = KeyCoverStatus.disabled

    var body: some View {
        Picker("keycover.setup.encryptionKey", selection: $keyOption) {
            Text("keycover.setup.useGeneratedKey")
                .tag(KeyCoverStatus.selfGeneratedPassword)
            Text("keycover.setup.useUserKey")
                .tag(KeyCoverStatus.userProvidedPassword)
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
            case .disabled:
                break
            }
        }

        VStack {
            Group {
                Text("keycover.setupPrompt.title")
                    .bold()
                SecureField("keycover.masterPassword", text: $masterKey)
                SecureField("keycover.confirmMasterPassword", text: $masterKeyConfirm)
                if masterKeyError {
                    Text("keycover.error.blankPassword")
                        .foregroundColor(.red)
                }
                if masterKeyConfirmError {
                    Text("keycover.error.notMatch")
                        .foregroundColor(.red)
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
                Button("button.Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("button.OK") {
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
                            case .disabled:
                                break
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

    @State private var keyOption = KeyCoverStatus.userProvidedPassword

    var body: some View {
        VStack {
            Text("keycover.changePasswordPrompt.title")
                .bold()
            SecureField("keycover.oldMasterPassword", text: $oldMasterKey)
            .disabled(KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword)

            Picker("keycover.setup.encryptionKey", selection: $keyOption) {
                Text("keycover.setup.useGeneratedKey")
                    .tag(KeyCoverStatus.selfGeneratedPassword)
                Text("keycover.setup.useUserKey")
                    .tag(KeyCoverStatus.userProvidedPassword)
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
                case .disabled:
                    break
                }
            }

            Group {
                SecureField("keycover.masterPassword", text: $masterKey)
                SecureField("keycover.confirmMasterPassword", text: $masterKeyConfirm)
                if oldMasterKeyError {
                    Text("keycover.error.incorrectPassword")
                        .foregroundColor(.red)
                        .padding()
                }
                if masterKeyError {
                    Text("keycover.error.blankPassword")
                        .foregroundColor(.red)
                        .padding()
                }
                if masterKeyConfirmError {
                    Text("keycover.error.notMatch")
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
                Button("button.Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("button.OK") {
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
                            case .disabled:
                                break
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

    @State private var keyOption = KeyCoverPreferences.shared.keyCoverEnabled

    var body: some View {
        VStack {
            Text("Enter your master password to remove KeyCover encryption")
                .bold()
            SecureField("keycover.masterPassword", text: $masterKey)
            .disabled(keyOption == .selfGeneratedPassword)
            if masterKeyError {
                Text("keycover.error.incorrectPassword")
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
                Button("button.Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("button.OK") {
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
