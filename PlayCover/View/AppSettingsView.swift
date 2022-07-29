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

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Toggle(NSLocalizedString("enable.km", comment: ""), isOn: $keymapping).padding()
                    Toggle(NSLocalizedString("enable.gaming", comment: ""), isOn: $gamingMode).padding()
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
            HStack(spacing: 0) {
                Spacer()
                Picker(selection: $selectedRefreshRate, label: Text("displayRefreshRate"), content: {
                    Text("60 Hz").tag(0)
                    Text("120 Hz").tag(1)
                }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300)
                Spacer()
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
