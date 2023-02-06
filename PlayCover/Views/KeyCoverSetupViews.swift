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

    var body: some View {
        VStack {
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
            Divider()
            HStack {
                // Spinner to indicate that data is being encrypted
                if isEncrypting {
                    ProgressView()
                        .padding()
                }
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Continue") {
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
                        KeyCoverMaster.setMasterKey(masterKey)
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
    @Binding var isPresented: Bool

    @State private var oldMasterKey = ""
    @State private var masterKey = ""
    @State private var masterKeyConfirm = ""
    @State private var isWorking = false

    @State private var oldMasterKeyError = false
    @State private var masterKeyError = false
    @State private var masterKeyConfirmError = false

    var body: some View {
        VStack {
            Text("Enter your old master password and a new one to update your KeyCover encryption key")
                .bold()
            SecureField("Old Master Password", text: $oldMasterKey)
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
            Divider()
            HStack {
                if isWorking {
                    ProgressView()
                        .padding()
                }
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Continue") {
                    if !KeyCoverMaster.validateMasterKey(oldMasterKey) {
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
                        isWorking = true
                        KeyCoverMaster.setMasterKey(masterKey)
                        isWorking = false
                        isPresented = false
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

    @State private var masterKey = ""
    @State private var isWorking = false

    @State private var masterKeyError = false

    var body: some View {
        VStack {
            Text("Enter your master password to remove KeyCover encryption")
                .bold()
            SecureField("Master Password", text: $masterKey)
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
                }
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Continue") {
                    if !KeyCoverMaster.validateMasterKey(masterKey) {
                        masterKeyError = true
                        return
                    }
                    Task(priority: .userInitiated) {
                        isWorking = true
                        KeyCoverMaster.removeMasterKey()
                        isWorking = false
                        isPresented = false
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(isWorking)
        .padding()
    }
}
