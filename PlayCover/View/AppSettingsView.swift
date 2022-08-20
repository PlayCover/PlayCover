//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 08.12.2021.
//

import Foundation
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
    @State var disableTimeout: Bool

    @State var resetCompletedAlert: Bool = false
    @State var selectedWindowSize: Int
    @State var enableWindowAutoSize: Bool
    @State var ipadModel: String
    @State var enableCustomWindowSize: Bool
    @State var customHeight: String
    @State var customWidth: String

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Toggle(NSLocalizedString("settings.toggle.km", comment: ""), isOn: $keymapping).padding()
                    Toggle(NSLocalizedString("settings.toggle.gaming", comment: ""), isOn: $gamingMode).padding()
                    if adaptiveDisplay {
                        if !enableCustomWindowSize {
                            Toggle(NSLocalizedString("settings.toggle.autoWindowResize", comment: ""),
                                   isOn: $enableWindowAutoSize)
                            .padding()
                        }
                        if !enableWindowAutoSize {
                            Toggle(NSLocalizedString("settings.text.customSize", comment: ""),
                                   isOn: $enableCustomWindowSize)
                            .padding()
                        }
                    }
                }
                HStack {
                    Image(systemName: "keyboard")
                        .font(.system(size: 96))
                        .foregroundColor(.accentColor)
                        .padding(.leading)
                    Text("settings.toggle.km.info")
                        .frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading, spacing: 0) {
                Toggle(NSLocalizedString(
                    "settings.toggle.adaptiveDisplay", comment: ""
                ), isOn: $adaptiveDisplay).padding()
                HStack {
                    Image(systemName: "display").font(.system(size: 96)).foregroundColor(.accentColor).padding(.leading)
                    Text("settings.toggle.adaptiveDisplay.info")
                        .frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading) {
                Toggle(isOn: $bypass) {
                    Text("settings.toggle.jbBypass")
                }.padding()
                HStack {
                    Image(systemName: "terminal.fill").font(.system(size: 96))
                        .foregroundColor(.accentColor).padding(.leading)
                    Text("settings.toggle.jbBypass.info")
                        .frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading, spacing: 0) {
                Toggle(isOn: $disableTimeout) {
                    Text("settings.toggle.disableDisplaySleep")
                }
                .padding()
                .help("settings.toggle.disableDisplaySleep.info")
                Spacer()
                Divider().padding(.leading, 36).padding(.trailing, 36)
                Spacer()
                Picker(selection: $selectedRefreshRate, label: Text("settings.picker.displayRefreshRate"), content: {
                    Text("60 Hz").tag(0)
                    Text("120 Hz").tag(1)
                }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300).padding()
                Picker(selection: $ipadModel, label: Text("settings.picker.iosDevice"), content: {
                    Text("iPad Pro (12.9-inch) (1st gen) | A9X | 4GB").tag("iPad6,7")
                    Text("iPad Pro (12.9-inch) (3rd gen) | A12Z | 4GB").tag("iPad8,6")
                    Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag("iPad13,8")
                }).pickerStyle(MenuPickerStyle()).frame(maxWidth: 300).padding()
                if adaptiveDisplay && !enableWindowAutoSize && !enableCustomWindowSize {
                    Spacer()
                    Picker(selection: $selectedWindowSize, label: Text("settings.picker.screenSize"), content: {
                        Text("720p").tag(0)
                        Text("1080p").tag(1)
                        Text("1440p").tag(2)
                        Text("4K").tag(3)
                    }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300).padding()
                    Spacer()
                    Picker(selection: $selectedWindowSize, label: Text("Portrait Mode"), content: {
                        Text("720p").tag(4)
                        Text("6.1\"").tag(5)
                    }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300).padding()
                Spacer()
                }
                if enableCustomWindowSize {
                    VStack {
                        HStack(spacing: 8) {
                            Text(NSLocalizedString(
                                "settings.text.customWidth", comment: ""
                            ))
                            TextField(NSLocalizedString(
                                "settings.text.customWidth", comment: ""
                            ), text: $customWidth)
                        }.frame(maxWidth: 300).padding().textFieldStyle(RoundedBorderTextFieldStyle())
                        HStack(spacing: 8) {
                            Text(NSLocalizedString(
                                "settings.text.customHeight", comment: ""
                            ))
                            TextField(NSLocalizedString(
                                "settings.text.customHeight", comment: ""
                            ), text: $customHeight)
                        }.frame(maxWidth: 300).padding() .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
            }
            VStack {
                Divider().padding(.leading, 36).padding(.trailing, 36)
                Text(NSLocalizedString(
                    "settings.slider.mouseSensitivity", comment: ""
                ) + String(format: "%.f", sensivity))
                Slider(value: $sensivity, in: 1...100).frame(maxWidth: 400)
            }

            Divider().padding(.leading, 36).padding(.trailing, 36)
            HStack {
                Spacer()
                Button("settings.reset") {
                    resetCompletedAlert.toggle()
                    settings.reset()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }.controlSize(.large).padding()
                Button("button.OK") {
                    settings.keymapping = keymapping
                    settings.adaptiveDisplay = adaptiveDisplay
                    settings.sensivity = sensivity
                    settings.bypass = bypass
                    settings.gamingMode = gamingMode
                    settings.enableWindowAutoSize = adaptiveDisplay && !enableCustomWindowSize
                                                    ? enableWindowAutoSize
                                                    : false
                    settings.ipadModel = ipadModel
                    if enableCustomWindowSize {
                        settings.gameWindowSizeHeight = (customHeight as NSString).floatValue
                        settings.gameWindowSizeWidth = (customWidth as NSString).floatValue
                    }
                    if enableWindowAutoSize && !enableCustomWindowSize {
                        settings.gameWindowSizeHeight = Float(NSScreen.main?.visibleFrame.height ?? 1080)
                        settings.gameWindowSizeWidth = Float(NSScreen.main?.visibleFrame.width ?? 1920)
                    } else {
                        if !enableCustomWindowSize {
                            setScreenSize(tag: selectedWindowSize, settings: settings)
                        }
                    }

                    if selectedRefreshRate == 1 {
                        settings.refreshRate = 120
                    } else {
                        settings.refreshRate = 60
                    }
                    settings.disableTimeout = disableTimeout
                    presentationMode.wrappedValue.dismiss()

                }
                .buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large).padding()
                .keyboardShortcut(.defaultAction)
                Spacer()
            }
        }.toast(isPresenting: $resetCompletedAlert) {
            AlertToast(type: .regular, title: NSLocalizedString("settings.resetCompleted", comment: ""))
        }
    }
}
