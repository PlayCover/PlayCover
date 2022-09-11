//
//  SignSetupView.swift
//  PlayCover
//
//  Created by Venti on 08/09/2022.
//

import SwiftUI

struct SignSetupView: View {
    @State var commandCopiedAlert = false

    @Binding var isSigningSetupShown: Bool

    var SIPEnabled = !SystemConfig.isSIPDisabled()
    var AMFIEnabledInNVRAM = SystemConfig.isPRAMValid()
    var AMFIEnabledInRunningOS = SystemConfig.isRunningAMFIEnabled()

    var body: some View {
        Group {
            Text("Configure Package Signing")
                .font(.largeTitle)
                .foregroundColor(.gray)
                .padding()
            Text("""
                    Package Signing helps fixing issues with apps that uses login, particularly games.

                    After logging in, you may be able to turn Package Signing off, if you so choose.
                    However, if you get logged out, you will need to enable Package Signing again
                    """)
            .multilineTextAlignment(.center)

            GroupBox {
                Spacer()
                HStack(alignment: .center) {
                    Image(systemName: "questionmark.circle.fill")
                        .help("""
                        SIP is required to be fully to partially disabled in order for AMFI to be turned off.
                        """)
                    Text("System Integrity Protection: ")
                        .font(.headline)
                    Text("\(SIPEnabled ? "Enabled" : "Disabled")")
                        .foregroundColor(SIPEnabled ? .red : .green)
                        .font(.headline)
                }
                Divider()
                HStack(alignment: .center) {
                    Image(systemName: "questionmark.circle.fill")
                        .help("""
                        AMFI is required to be turned off in order to allow fake signing of apps, \
                        which helps fixing certain issues with apps that verifies their integrity
                        """)
                    Text("Apple Mobile File Integrity: ")
                        .font(.headline)
                    if AMFIEnabledInNVRAM {
                        if !AMFIEnabledInRunningOS {
                            Text("Pending Reboot")
                                .foregroundColor(.yellow)
                                .font(.headline)
                        } else {
                            Text("Disabled")
                                .foregroundColor(.green)
                                .font(.headline)
                        }
                    } else {
                        Text("Enabled")
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                }
                Spacer()
            }
            .padding()
            Group {
                if SIPEnabled {
                    Text("Please disable SIP from Recovery Mode")
                        .font(.subheadline)
                    Spacer()
                    Button("Shut down my Mac") {
                        let source = "tell application \"Finder\"\nshut down\nend tell"
                        let script = NSAppleScript(source: source)
                        script?.executeAndReturnError(nil)
                        isSigningSetupShown = false
                    }
                } else {
                    if !AMFIEnabledInNVRAM && !AMFIEnabledInRunningOS {
                        Text("Please disable AMFI")
                            .font(.subheadline)
                        Spacer()
                        Button("Copy Command to Clipboard") {
                            let disableCommand =
                            """
                            sudo nvram boot-args=\"amfi_get_out_of_my_way=0x1 ipc_control_port_options=0\" \
                            && sudo reboot
                            """
                            NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                            NSPasteboard.general.setString(disableCommand, forType: NSPasteboard.PasteboardType.string)
                            commandCopiedAlert = true
                        }
                    } else if AMFIEnabledInNVRAM {
                        if !AMFIEnabledInRunningOS {
                            Text("AMFI Disabled. Please reboot")
                                .font(.subheadline)
                            Spacer()
                            Button("Restart my Mac") {
                                let source = "tell application \"Finder\"\nrestart\nend tell"
                                let script = NSAppleScript(source: source)
                                script?.executeAndReturnError(nil)
                                isSigningSetupShown = false
                            }
                        } else {
                            Text("Package Signing has been configured. You're good to go!")
                        }
                    }
                }
            }
            .alert(isPresented: $commandCopiedAlert) {
                Alert(title: Text("Command Copied!"),
                      message: Text("Please paste and run the command in Terminal.app. Your Mac will reboot after"),
                      dismissButton: .default(Text("OK")))
            }
            Divider()
            HStack {
                Button("Help") {
                    NSWorkspace.shared.open(
                        URL(string: "https://docs.playcover.io/getting_started/troubleshoot_login")!)
                }
                Button("Dismiss", role: .cancel) {
                    isSigningSetupShown = false
                }
            }
            .fixedSize(horizontal: true, vertical: true)
        }
        .padding()
    }
}

struct SignSetupView_Previews: PreviewProvider {
    static var previews: some View {
        SignSetupView(isSigningSetupShown: .constant(true))
    }
}
