//
//  KeyCoverViews.swift
//  PlayCover
//
//  Created by Venti on 01/02/2023.
//

import SwiftUI

struct KeyCoverUnlockingPrompt: View {
    @State private var password = ""
    @State private var passwordError = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "lock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("Enter your master password to unlock KeyCover")
                    .padding()
            }
            .padding()
                SecureField("Master Password", text: $password)
                    .padding()
                if passwordError {
                    Text("Incorrect password")
                        .foregroundColor(.red)
                        .padding()
            }
            Divider()
            HStack {
                Spacer()
                Button("Cancel") {
                    KeyCoverObservable.shared.isKeyCoverUnlockingPromptShown = false
                }
                .keyboardShortcut(.cancelAction)
                Button("Unlock") {
                    unlock()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }

    func unlock() {
        if KeyCoverMaster.shared.validateMasterKey(password) {
            // if Smart Unlock is enabled, store the masterKey
            KeyCover.shared.keyCoverPlainTextKey = password
        } else {
            passwordError = true
            return
        }
        KeyCoverObservable.shared.isKeyCoverUnlockingPromptShown = false
    }
}
