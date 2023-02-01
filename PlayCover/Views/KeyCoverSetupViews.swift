//
//  KeyCoverViews.swift
//  PlayCover
//
//  Created by Venti on 31/01/2023.
//

import Foundation
import SwiftUI

struct KeyCoverInitialSetupView: View {
    let window: NSWindow

    enum SetupStep {
        case introduction
        case setMasterKey
        case confirmMasterKey
        case encryptionInProcess
        case done
    }

    @State private var setupStep: SetupStep = .introduction
    @State private var masterKey: String = ""
    @State private var masterKeyConfirmation: String = ""
    @State private var showPassword: Bool = false
    @State private var showPasswordConfirmation: Bool = false
    @State private var showPasswordError: Bool = false

    var body: some View {
        VStack {
            switch setupStep {
            case .introduction:
                Group {
                    Spacer()
                    Image(systemName: "key.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 100)
                        .rotationEffect(.degrees(45))
                        .foregroundColor(.blue)
                        .padding()
                    Text("Welcome to KeyCover!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                    Text("""
KeyCover securely encrypts your PlayChain data with a password of your choosing.
This password is called the master key.
You will need to enter this master key every time you want to access your PlayChain data.
You cannot recover the master key, so make sure you keep it safe
""")
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.subheadline)
                    Spacer()
                    Divider()
                    HStack {
                        Spacer()
                        Button("Cancel") {
                            window.close()
                        }
                        Button("Next") {
                            setupStep = .setMasterKey
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            case .setMasterKey:
                Group {
                    Text("Set Master Key")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding()
                    Text("""
                    Your master key is used to encrypt your PlayChain data. Please enter a master key of your choosing.
                    Warning: If you lose this key, you will lose ALL of your PlayChain data.
                    """)
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.subheadline)
                    Spacer()
                    HStack {
                        if showPassword {
                            TextField("Master Key", text: $masterKey)
                        } else {
                            SecureField("Master Key", text: $masterKey)
                        }
                        Button(action: {
                            showPassword.toggle()
                        }, label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                        })
                    }
                    .padding()
                    if showPasswordError {
                        Text("Master keys cannot be empty.").foregroundColor(.red)
                    }
                    Spacer()
                    Divider()
                    HStack {
                        Spacer()
                        Button("Back") {
                            setupStep = .introduction
                        }
                        Button("Next") {
                            if masterKey.isEmpty {
                                showPasswordError = true
                                return
                            } else {
                                showPasswordError = false
                                setupStep = .confirmMasterKey
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            case .confirmMasterKey:
                Group {
                    Text("Confirm Master Key")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding()
                    Text("Please confirm your master key.")
                        .multilineTextAlignment(.center)
                        .padding()
                        .font(.subheadline)
                    Spacer()
                    HStack {
                        if showPasswordConfirmation {
                            TextField("Master Key", text: $masterKeyConfirmation)
                        } else {
                            SecureField("Master Key", text: $masterKeyConfirmation)
                        }
                        Button(action: {
                            showPasswordConfirmation.toggle()
                        }, label: {
                            Image(systemName: showPasswordConfirmation ? "eye.slash" : "eye")
                        })
                    }
                    .padding()
                    if showPasswordError {
                        Text("Master keys do not match.").foregroundColor(.red)
                    }
                    Divider()
                    HStack {
                        Spacer()
                        Button("Back") {
                            setupStep = .setMasterKey
                        }
                        Button("Next") {
                            if masterKey == masterKeyConfirmation {
                                setupStep = .encryptionInProcess
                                DispatchQueue.global(qos: .userInitiated).async {
                                    KeyCoverMaster.setMasterKey(masterKey)
                                    DispatchQueue.main.async {
                                        setupStep = .done
                                    }
                                }
                            } else {
                                showPasswordError = true
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            case .encryptionInProcess:
                Group {
                    Text("Encrypting PlayChain data...")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                        .padding()
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            case .done:
                VStack {
                    Text("KeyCover Setup Complete").font(.title)
                    Text("""
                    Your PlayChain data has been encrypted with your master key.
                    You will need to enter your master key every time you want to access app keychains.
                    """)
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding()
                }
                Spacer()
                Divider()
                HStack {
                    Spacer()
                    Button("Finish") {
                        window.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }

    static func openWindow() {
        // Open a borderless window that closes when isPresented is set to false
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 700),
            styleMask: [.titled],
            backing: .buffered, defer: false
        )
        window.center()
        window.setFrameAutosaveName("KeyCover Setup")
        window.title = "KeyCover Setup"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: KeyCoverInitialSetupView(window: window))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct KeyCoverUpdatePasswordView: View {
    let window: NSWindow

    enum SetupStep {
        case introduction
        case verifyMasterKey
        case setMasterKey
        case confirmMasterKey
        case encryptionInProcess
        case done
    }

    @State var setupStep: SetupStep = .introduction
    @State var masterKey: String = ""
    @State var masterKeyConfirmation: String = ""
    @State var showPassword: Bool = false
    @State var showPasswordConfirmation: Bool = false
    @State var showPasswordError: Bool = false

    var body: some View {
        VStack {
            switch setupStep {
            case .introduction:
                Text("Welcome to KeyCover!")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text("""
KeyCover securely encrypts your PlayChain data with a password of your choosing.
This password is called the master key.
You will need to enter this master key every time you want to access your PlayChain data.
You cannot recover the master key, so make sure you keep it safe
"""
                )
                .multilineTextAlignment(.center)
                .padding()
                .font(.subheadline)
                Spacer()
                Divider()
                HStack {
                    Spacer()
                    Button("Cancel") {
                        window.close()
                    }
                    Button("Next") {
                        setupStep = .verifyMasterKey
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .verifyMasterKey:
                Text("Verify Master Key")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text("Please enter your current master key.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.subheadline)
                Spacer()
                HStack {
                    if showPassword {
                        TextField("Master Key", text: $masterKey)
                    } else {
                        SecureField("Master Key", text: $masterKey)
                    }
                    Button(action: {
                        showPassword.toggle()
                    }, label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    })
                }
                .padding()
                if showPasswordError {
                    Text("Master key is incorrect.").foregroundColor(.red)
                }
                Divider()
                HStack {
                    Spacer()
                    Button("Back") {
                        setupStep = .introduction
                    }
                    Button("Next") {
                        if KeyCoverMaster.validateMasterKey(masterKey) {
                            setupStep = .setMasterKey
                        } else {
                            showPasswordError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .setMasterKey:
                Text("Set Master Key").font(.title)
                Text("""
                    Your master key is used to encrypt your PlayChain data. Please enter a master key of your choosing.
                    Warning: If you lose this key, you will lose ALL of your PlayChain data.
                    """)
                .multilineTextAlignment(.center)
                .padding()
                .font(.subheadline)
                Spacer()
                HStack {
                    if showPassword {
                        TextField("Master Key", text: $masterKey)
                    } else {
                        SecureField("Master Key", text: $masterKey)
                    }
                    Button(action: {
                        showPassword.toggle()
                    }, label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    })
                }
                .padding()
                Divider()
                HStack {
                    Spacer()
                    Button("Back") {
                        setupStep = .verifyMasterKey
                    }
                    Button("Next") {
                        setupStep = .confirmMasterKey
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .confirmMasterKey:
                Text("Confirm Master Key")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text("Please confirm your master key.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.subheadline)
                Spacer()
                HStack {
                    if showPasswordConfirmation {
                        TextField("Master Key", text: $masterKeyConfirmation)
                    } else {
                        SecureField("Master Key", text: $masterKeyConfirmation)
                    }
                    Button(action: {
                        showPasswordConfirmation.toggle()
                    }, label: {
                        Image(systemName: showPasswordConfirmation ? "eye.slash" : "eye")
                    })
                }
                if showPasswordError {
                    Text("Master keys do not match.").foregroundColor(.red)
                }
                HStack {
                    Button("Back") {
                        setupStep = .setMasterKey
                    }
                    Button("Next") {
                        if masterKey == masterKeyConfirmation {
                            setupStep = .encryptionInProcess
                            DispatchQueue.global(qos: .userInitiated).async {
                                KeyCoverMaster.setMasterKey(masterKey)
                                DispatchQueue.main.async {
                                    setupStep = .done
                                }
                            }
                        } else {
                            showPasswordError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .encryptionInProcess:
                Text("Encrypting PlayChain data...")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            case .done:
                Text("KeyCover Setup Complete")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text("""
                     Your PlayChain data has been encrypted with your master key.\
                     You will need to enter your master key every time you want to access your PlayChain data.
                    """)
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.subheadline)
                Spacer()
                Divider()
                HStack {
                    Spacer()
                    Button("Finish") {
                        window.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }
    static func openWindow() {
        // Open a borderless window that closes when isPresented is set to false
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 700),
            styleMask: [.titled],
            backing: .buffered, defer: false
        )
        window.center()
        window.setFrameAutosaveName("KeyCover Setup")
        window.title = "KeyCover Setup"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: KeyCoverUpdatePasswordView(window: window))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct KeyCoverInitialSetupView_Previews: PreviewProvider {
    static var previews: some View {
        KeyCoverInitialSetupView(window: NSWindow())
    }
}

struct KeyCoverRemovalView: View {
    let window: NSWindow

    enum SetupStep {
        case introduction
        case verifyMasterKey
        case encryptionInProcess
        case done
    }

    @State var setupStep: SetupStep = .introduction
    @State var masterKey: String = ""
    @State var showPassword: Bool = false
    @State var showPasswordError: Bool = false

    var body: some View {
        VStack {
            switch setupStep {
            case .introduction:
                Text("Welcome to KeyCover!")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text(
                        """
KeyCover securely encrypts your PlayChain data with a password of your choosing. This password is called the master key.
You will need to enter this master key every time you want to access your PlayChain data.
You cannot recover the master key, so make sure you keep it safe
""")
                .multilineTextAlignment(.center)
                .padding()
                .font(.subheadline)
                Spacer()
                HStack {
                    Button("Cancel") {
                        window.close()
                    }
                    Button("Next") {
                        setupStep = .verifyMasterKey
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .verifyMasterKey:
                Text("Verify Master Key")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text("Please enter your current master key.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .font(.subheadline)
                Spacer()
                HStack {
                    if showPassword {
                        TextField("Master Key", text: $masterKey)
                    } else {
                        SecureField("Master Key", text: $masterKey)
                    }
                    Button(action: {
                        showPassword.toggle()
                    }, label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                    })
                }
                if showPasswordError {
                    Text("Master key is incorrect.").foregroundColor(.red)
                }
                HStack {
                    Button("Back") {
                        setupStep = .introduction
                    }
                    Button("Next") {
                        if KeyCoverMaster.validateMasterKey(masterKey) {
                            setupStep = .encryptionInProcess
                            DispatchQueue.global(qos: .userInitiated).async {
                                KeyCoverMaster.removeMasterKey()
                                DispatchQueue.main.async {
                                    setupStep = .done
                                }
                            }
                        } else {
                            showPasswordError = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .encryptionInProcess:
                Text("Decrypting PlayChain data...")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            case .done:
                Text("KeyCover Removal Complete")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
                Text("Your PlayChain data has been decrypted successfully.")
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
                Divider()
                Button("Finish") {
                    window.close()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    static func openWindow() {
        // Open a borderless window that closes when isPresented is set to false
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 700),
            styleMask: [.titled],
            backing: .buffered, defer: false
        )
        window.center()
        window.setFrameAutosaveName("KeyCover Setup")
        window.title = "KeyCover Setup"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: KeyCoverRemovalView(window: window))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
