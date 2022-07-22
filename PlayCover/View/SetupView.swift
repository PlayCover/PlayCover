//
//  SetupView.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 08.11.2021.
//

import Foundation
import SwiftUI

struct SetupView: View {
    @Environment(\.presentationMode) var presentationMode

    typealias PromptResponseClosure = (_ strResponse: String, _ bResponse: Bool) -> Void

    func promptForReply(_ strMsg: String, _ strInformative: String, completion: PromptResponseClosure) {
        let alert: NSAlert = NSAlert()

        alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))      // 1st button
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))  // 2nd button
        alert.messageText = strMsg
        alert.informativeText = strInformative

        let txt = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))

        txt.stringValue = ""

        alert.accessoryView = txt
        let response: NSApplication.ModalResponse = alert.runModal()

        var bResponse = false
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            bResponse = true
        }

        completion(txt.stringValue, bResponse)

    }

    func playSignPromt(_ firstTime: Bool) {
        let text = firstTime ? NSLocalizedString("setup.enterLoginPassword", comment: "") :
            NSLocalizedString("setup.incorrectPassword", comment: "")

        promptForReply(text,
                       NSLocalizedString("setup.enterLoginPassword.info", comment: "")) { strResponse, _ in
            if SystemConfig.enablePlaySign(strResponse) {
                if SystemConfig.isPRAMValid() {
                    presentationMode.wrappedValue.dismiss()
                    Log.shared.msg("setup.enterLoginPassword")
                } else {
                    playSignPromt(false)
                }
            } else {
                playSignPromt(false)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !SystemConfig.isSIPDisabled() {
                Text("setupView.header")
                    .padding([.horizontal, .top])
                    .font(.title.weight(.heavy))
                Text("setupView.subheader")
                    .padding(.horizontal)
                    .padding(.top, -4)

                Spacer()

                VStack(alignment: .leading, spacing: 5) {
                    Group {
                        Text("setupView.1")
                        Text("setupView.2")
                        Text("setupView.3")
                        Text("setupView.4")
                        Text("setupView.5")
                        HStack(spacing: 4) {
                            Text("setupView.6")
                            Text("csrutil disable").textSelection(.enabled).font(.monospaced(.body)())
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.25, green: 0.25, blue: 0.25))
                                .cornerRadius(5)
                                .foregroundColor(Color(hex: 0xFFFFFF))
                        }
                        Text("setupView.7")
                        Text("setupView.8")

                        Spacer()

                        Text("setupView.9").font(.callout)
                    }

                    GroupBox(label: Label(NSLocalizedString("setupView.vidTutorials", comment: ""),
                                          systemImage: "play.rectangle")) {
                        HStack {
                            ZStack {
                                Link("setupView.youtube", destination:
                                        URL(string: "https://www.youtube.com/watch?v=H3CoI84s_FI")!)
                                    .font(.title3)
                                    .padding(.vertical, 4).padding(.horizontal, 10)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.unemphasizedSelectedContentBackgroundColor))
                            )
                            ZStack {
                                Link("setupView.bilibili", destination:
                                        URL(string: "https://www.bilibili.com/video/BV1Th411q7Lt")!)
                                    .font(.title3)
                                    .padding(.vertical, 4).padding(.horizontal, 10)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(NSColor.unemphasizedSelectedContentBackgroundColor))
                            )
                        }
                        .padding(2)
                    }.padding(.top, 8)

                    Button("button.Dismiss") { presentationMode.wrappedValue.dismiss() }
                        .padding([.top, .bottom])
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .accentColor(.accentColor)
                }.padding(.horizontal)
            } else if !SystemConfig.isPRAMValid() {
                Text("setupView.pressButtonAndEnterPassword")
                    .padding()
                    .font(.system(size: 18.0, weight: .thin))
                    .padding()
                Button("setupView.pressButtonAndEnterPassword.button") {
                    playSignPromt(true)
                }.padding()
            }
        }.frame(maxWidth: 750)
    }
}
