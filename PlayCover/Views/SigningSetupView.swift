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
            Text("configSigning.header")
                .font(.largeTitle)
                .foregroundColor(.gray)
                .padding()
            Text("configSigning.subtext")
            .multilineTextAlignment(.center)

            GroupBox {
                Spacer()
                HStack(alignment: .center) {
                    Image(systemName: "questionmark.circle.fill")
                        .help("configSigning.info.SIP")
                    Text("configSigning.info.SIPHeader")
                        .font(.headline)
                    Spacer()
                    Text((SIPEnabled ? "state.enabled" : "state.disabled"))
                        .foregroundColor(SIPEnabled ? .red : .green)
                        .font(.headline)
                }
                .padding(.leading, 5)
                .padding(.trailing, 5)
                Divider()
                HStack(alignment: .center) {
                    Image(systemName: "questionmark.circle.fill")
                        .help("configSigning.info.AMFI")
                    Text("configSigning.info.AMFIHeader")
                        .font(.headline)
                    Spacer()
                    if AMFIEnabledInNVRAM {
                        if !AMFIEnabledInRunningOS {
                            Text("state.pendingReboot")
                                .foregroundColor(.yellow)
                                .font(.headline)
                        } else {
                            Text("state.disabled")
                                .foregroundColor(.green)
                                .font(.headline)
                        }
                    } else {
                        Text("state.enabled")
                            .foregroundColor(.red)
                            .font(.headline)
                    }
                }
                .padding(.leading, 5)
                .padding(.trailing, 5)
                Spacer()
            }
            .padding()
            Group {
                if SIPEnabled {
                    Text("configSigning.step.disableSIP")
                        .font(.subheadline)
                    Spacer()
                    Button("configSigning.action.shutdown") {
                        let source = "tell application \"Finder\"\nshut down\nend tell"
                        let script = NSAppleScript(source: source)
                        script?.executeAndReturnError(nil)
                        isSigningSetupShown = false
                    }
                } else {
                    if !AMFIEnabledInNVRAM && !AMFIEnabledInRunningOS {
                        Text("configSigning.step.disableAMFI")
                            .font(.subheadline)
                        Spacer()
                        Button("configSigning.action.copyCommand") {
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
                            Text("configSigning.step.AMFIreboot")
                                .font(.subheadline)
                            Spacer()
                            Button("configSigning.action.restart") {
                                let source = "tell application \"Finder\"\nrestart\nend tell"
                                let script = NSAppleScript(source: source)
                                script?.executeAndReturnError(nil)
                                isSigningSetupShown = false
                            }
                        } else {
                            Text("configSigning.step.complete")
                        }
                    }
                }
            }
            .alert(isPresented: $commandCopiedAlert) {
                Alert(title: Text("configSigning.alert.copied"),
                      message: Text("configSigning.alert.info"),
                      dismissButton: .default(Text("button.OK")))
            }
            Divider()
            HStack {
                Button("button.Help") {
                    if let url = URL(string: "https://docs.playcover.io/getting_started/troubleshoot_login") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("button.Dismiss", role: .cancel) {
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
