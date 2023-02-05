//
//  KeyCoverViews.swift
//  PlayCover
//
//  Created by Venti on 01/02/2023.
//

import SwiftUI

struct KeyCoverUnlockingPrompt: View {
    let window: NSWindow
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
                    window.close()
                }
                Button("Unlock") {
                    if KeyCoverMaster.validateMasterKey(password) {
                        // if Smart Unlock is enabled, store the masterKey
                        KeyCover.shared.keyCoverPlainTextKey = password
                    } else {
                        passwordError = true
                        return
                    }
                    window.close()
                }
            }
            .padding()
        }
    }

    static func openWindow() -> NSWindow {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 200, height: 100),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Unlock KeyCover")
        window.contentView = NSHostingView(rootView: KeyCoverUnlockingPrompt(window: window))
        window.makeKeyAndOrderFront(nil)
        return window
    }
}
