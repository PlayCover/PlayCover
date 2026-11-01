//
//  KeyCoverViews.swift
//  PlayCover
//
//  Created by Venti on 01/02/2023.
//

import SwiftUI

struct KeyCoverUnlockingPrompt: View {
    @Environment(KeyCoverService.self) private var keyCover
    @State private var password = ""
    @State private var passwordError = false

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "lock")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("keycover.unlockPrompt.title")
                    .padding()
            }
            .padding()
                SecureField("keycover.masterPassword", text: $password)
                    .padding()
                if passwordError {
                    Text("keycover.error.incorrectPassword")
                        .foregroundColor(.red)
                        .padding()
            }
            Divider()
            HStack {
                Spacer()
                Button("button.Cancel") {
                    keyCover.dismissUnlockPrompt()
                }
                .keyboardShortcut(.cancelAction)
                Button("button.Unlock") {
                    unlock()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }

    func unlock() {
        passwordError = !keyCover.submitUnlock(password: password)
    }
}
