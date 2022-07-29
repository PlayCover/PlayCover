//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 08.12.2021.
//

import SwiftUI
import AlertToast

struct AppSettingsView: View {
    @State var settings: AppSettings

    @State var adaptiveDisplay: Bool
    @State var keymapping: Bool
    @State var gamingMode: Bool
    @State var bypass: Bool
    @State var selectedRefreshRate: Int
    @State var sensivity: Float

    @State var resetCompletedAlert: Bool = false
    @State var selectedWindowSize: Int
    @State var enableWindowAutoSize: Bool
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Toggle(NSLocalizedString("enable.km", comment: ""), isOn: $keymapping).padding()
                    Toggle(NSLocalizedString("enable.gaming", comment: ""), isOn: $gamingMode).padding()
                    if adaptiveDisplay {
                        Toggle(NSLocalizedString("Enable Auto Window Size", comment: ""),
                               isOn: $enableWindowAutoSize).padding()
                    }
                }
                HStack {
                    Image(systemName: "keyboard")
                        .font(.system(size: 96))
                        .foregroundColor(.accentColor)
                        .padding(.leading)
                    Text("enable.km.info")
                        .frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading, spacing: 0) {
                Toggle(NSLocalizedString("enable.adaptiveDisplay", comment: ""), isOn: $adaptiveDisplay).padding()
                HStack {
                    Image(systemName: "display").font(.system(size: 96)).foregroundColor(.accentColor).padding(.leading)
                    Text("enable.adaptiveDisplay.info")
                        .frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading) {
                Toggle(isOn: $bypass) {
                    Text("enable.jbBypass")
                }.padding()
                HStack {
                    Image(systemName: "terminal.fill").font(.system(size: 96))
                        .foregroundColor(.accentColor).padding(.leading)
                    Text("enable.jbBypass.info")
                        .frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Picker(selection: $selectedRefreshRate, label: Text("displayRefreshRate"), content: {
                    Text("60 Hz").tag(0)
                    Text("120 Hz").tag(1)
                }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300).padding()
                if adaptiveDisplay && !enableWindowAutoSize {
                    Spacer()
                    Picker(selection: $selectedWindowSize, label: Text("Screen size"), content: {
                        Text("1080p").tag(0)
                        Text("1440p").tag(1)
                        Text("4k").tag(2)
                    }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300).padding()
                Spacer()
                }
            }
            VStack {
                Divider().padding(.leading, 36).padding(.trailing, 36)
                Text(NSLocalizedString("mouseSensitivity", comment: "") + String(format: "%.f", sensivity))
                Slider(value: $sensivity, in: 1...100).frame(maxWidth: 400)
            }

            Divider().padding(.leading, 36).padding(.trailing, 36)
            HStack {
                Spacer()
                Button("settings.reset") {
                    resetCompletedAlert.toggle()
                    settings.reset()
                }
                .padding([.top, .bottom])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.accentColor)
                Button("button.OK") {
                    settings.keymapping = keymapping
                    settings.adaptiveDisplay = adaptiveDisplay
                    settings.sensivity = sensivity
                    settings.bypass = bypass
                    settings.gamingMode = gamingMode
                    settings.enableWindowAutoSize = adaptiveDisplay ? enableWindowAutoSize : false
                    if enableWindowAutoSize {
                        settings.gameWindowSizeHeight = Float(NSScreen.main?.visibleFrame.height ?? 1080)
                        settings.gameWindowSizeWidth = Float(NSScreen.main?.visibleFrame.width ?? 1920)
                    } else {
                        if selectedWindowSize == 0 {
                            settings.gameWindowSizeHeight = 1080
                            settings.gameWindowSizeWidth = (1080 * 1.77777777777778) + 100
                        } else if selectedWindowSize == 1 {
                            settings.gameWindowSizeHeight = 1440
                            settings.gameWindowSizeWidth = (1400 * 1.77777777777778) + 100
                        } else {
                            settings.gameWindowSizeHeight = 2160
                            settings.gameWindowSizeWidth = (2160 * 1.77777777777778) + 100
                        }
                    }

                    if selectedRefreshRate == 1 {
                        settings.refreshRate = 120
                    } else {
                        settings.refreshRate = 60
                    }

                    presentationMode.wrappedValue.dismiss()

                }
                .padding([.top, .bottom])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.accentColor)
                Spacer()
            }
        }.toast(isPresenting: $resetCompletedAlert) {
            AlertToast(type: .regular, title: NSLocalizedString("settings.resetCompleted", comment: ""))
        }
    }
}
