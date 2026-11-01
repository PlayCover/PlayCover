//
//  KeyCoverViews.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import Foundation
import SwiftUI

struct KeyCoverInitialSetupView: View {
    @Environment(KeyCoverService.self) private var keyCover
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
        .onChange(of: keyOption) {
            switch keyOption {
            case .selfGeneratedPassword:
                keyCoverPassword = keyCover.generateVerySecurePassword()
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
                        isEncrypting = true
                        await keyCover.setPassword(keyCoverPassword, status: keyOption)
                        isEncrypting = false
                        isPresented = false
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
    @Environment(KeyCoverService.self) private var keyCover
    @Environment(KeyCoverPreferences.self) private var preferences
    @Binding var isPresented: Bool

    @State private var oldKeyCoverPassword = ""
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
            .disabled(preferences.keyCoverEnabled == .selfGeneratedPassword)

            Picker("keycover.setup.encryptionKey", selection: $keyOption) {
                Text("keycover.setup.useGeneratedKey")
                    .tag(KeyCoverStatus.selfGeneratedPassword)
                Text("keycover.setup.useUserKey")
                    .tag(KeyCoverStatus.userProvidedPassword)
            }
            .pickerStyle(RadioGroupPickerStyle())
            .padding()
            .onChange(of: keyOption) {
                switch keyOption {
                case .selfGeneratedPassword:
                    keyCoverPassword = keyCover.generateVerySecurePassword()
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
                        if !keyCover.validatePassword(oldKeyCoverPassword) {
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
                        isWorking = true
                        await keyCover.setPassword(keyCoverPassword, status: keyOption)
                        isWorking = false
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(isWorking)
        .padding()
        .onAppear {
            if preferences.keyCoverEnabled == .selfGeneratedPassword {
                oldKeyCoverPassword = keyCover.plainTextKey ?? ""
            }
        }
    }
}

struct KeyCoverRemovalView: View {
    @Environment(KeyCoverService.self) private var keyCover
    @Environment(KeyCoverPreferences.self) private var preferences
    @Binding var isPresented: Bool

    @State private var keyCoverPassword = ""
    @State private var isWorking = false

    @State private var keyCoverPasswordError = false

    @State private var keyOption = KeyCoverStatus.disabled

    var body: some View {
        VStack {
            Text("keycover.removePrompt.title")
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
                        if !keyCover.validatePassword(keyCoverPassword) {
                            keyCoverPasswordError = true
                            return
                        }
                        isWorking = true
                        await keyCover.removePassword()
                        isWorking = false
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(isWorking)
        .padding()
        .onAppear {
            keyOption = preferences.keyCoverEnabled
            if keyOption == .selfGeneratedPassword {
                keyCoverPassword = keyCover.plainTextKey ?? ""
            }
        }
    }
}
