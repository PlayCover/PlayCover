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

    @State private var keyCoverPassword = ""
    @State private var keyCoverPasswordConfirmed = ""
    @State private var isEncrypting = false

    @State private var keyCoverPasswordError = false
    @State private var keyCoverConfirmError = false

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
                keyCoverPassword = KeyCoverPassword.shared.generateVerySecurePassword()
                keyCoverPasswordConfirmed = keyCoverPassword
            case .userProvidedPassword:
                keyCoverPassword = ""
                keyCoverPasswordConfirmed = ""
            case .disabled:
                break
            }
        }

        VStack {
            Group {
                Text("keycover.setupPrompt.title")
                    .bold()
                SecureField("keycover.masterPassword", text: $keyCoverPassword)
                SecureField("keycover.confirmMasterPassword", text: $keyCoverPasswordConfirmed)
                if keyCoverPasswordError {
                    Text("keycover.error.blankPassword")
                        .foregroundColor(.red)
                }
                if keyCoverConfirmError {
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
                        if keyCoverPassword == "" {
                            keyCoverPasswordError = true
                            return
                        }
                        if keyCoverPassword != keyCoverPasswordConfirmed {
                            keyCoverConfirmError = true
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
                            KeyCoverPassword.shared.setKeyCoverPassword(keyCoverPassword)
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

    @State private var oldKeyCoverPassword = KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword ?
                                        KeyCover.shared.keyCoverPlainTextKey ?? "" : ""
    @State private var keyCoverPassword = ""
    @State private var keyCoverPasswordConfirm = ""
    @State private var isWorking = false

    @State private var oldKeyCoverPasswordError = false
    @State private var keyCoverPasswordError = false
    @State private var keyCoverPasswordConfirmError = false

    @State private var keyOption = KeyCoverStatus.userProvidedPassword

    var body: some View {
        VStack {
            Text("keycover.changePasswordPrompt.title")
                .bold()
            SecureField("keycover.oldMasterPassword", text: $oldKeyCoverPassword)
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
                    keyCoverPassword = KeyCoverPassword.shared.generateVerySecurePassword()
                    keyCoverPasswordConfirm = keyCoverPassword
                case .userProvidedPassword:
                    keyCoverPassword = ""
                    keyCoverPasswordConfirm = ""
                case .disabled:
                    break
                }
            }

            Group {
                SecureField("keycover.masterPassword", text: $keyCoverPassword)
                SecureField("keycover.confirmMasterPassword", text: $keyCoverPasswordConfirm)
                if oldKeyCoverPasswordError {
                    Text("keycover.error.incorrectPassword")
                        .foregroundColor(.red)
                        .padding()
                }
                if keyCoverPasswordError {
                    Text("keycover.error.blankPassword")
                        .foregroundColor(.red)
                        .padding()
                }
                if keyCoverPasswordConfirmError {
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
                        if !KeyCoverPassword.shared.validatePassword(oldKeyCoverPassword) {
                            oldKeyCoverPasswordError = true
                            return
                        }
                        if keyCoverPassword == "" {
                            keyCoverPasswordError = true
                            return
                        }
                        if keyCoverPassword != keyCoverPasswordConfirm {
                            keyCoverPasswordConfirmError = true
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
                                KeyCoverPassword.shared.setKeyCoverPassword(keyCoverPassword)
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

    @State private var keyCoverPassword = KeyCoverPreferences.shared.keyCoverEnabled == .selfGeneratedPassword ?
                                    KeyCover.shared.keyCoverPlainTextKey ?? "" : ""
    @State private var isWorking = false

    @State private var keyCoverPasswordError = false

    @State private var keyOption = KeyCoverPreferences.shared.keyCoverEnabled

    var body: some View {
        VStack {
            Text("Enter your master password to remove KeyCover encryption")
                .bold()
            SecureField("keycover.masterPassword", text: $keyCoverPassword)
            .disabled(keyOption == .selfGeneratedPassword)
            if keyCoverPasswordError {
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
                        if !KeyCoverPassword.shared.validatePassword(keyCoverPassword) {
                            keyCoverPasswordError = true
                            return
                        }
                        Task(priority: .userInitiated) {
                            isWorking = true
                            KeyCoverPassword.shared.removeKeyCoverPassword()
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
