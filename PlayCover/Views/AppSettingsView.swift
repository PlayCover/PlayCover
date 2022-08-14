//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State var settings: AppSettings

    @State var selection: Int = 2
    @State var resetCompletedAlert: Bool = false

    // TODO: Remove hardcoded strings
    // TODO: Fix adapative display backend
    var body: some View {
        VStack {
            HStack {
                Text("\(settings.info.displayName.isEmpty ? settings.info.bundleName : settings.info.displayName) Settings")
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            HStack {
                Toggle(NSLocalizedString("settings.toggle.km", comment: ""), isOn: $settings.keymapping)
                    .help("settings.toggle.km.info")
                Toggle("Enable mouse mapping", isOn: $settings.gamingMode)
                Spacer()
            }
            HStack {
                Slider(value: $settings.sensivity, in: 0...100, label: {
                    Text(NSLocalizedString("settings.slider.mouseSensitivity", comment: "")
                         + String(format: "%.f", settings.sensivity))
                })
                .frame(maxWidth: 400)
                Spacer()
            }
            Divider()
                .padding(.vertical)
            HStack {
                Picker("Adaptive resolution:", selection: $selection) {
                    Text("Off").tag(0)
                    Text("Auto").tag(1)
                    Text("1080p").tag(2)
                    Text("1440p").tag(3)
                    Text("4K").tag(4)
                }
                .fixedSize()
                .frame(alignment: .leading)
                .help("settings.toggle.adaptiveDisplay.info")
                Spacer()
            }
            HStack {
                Picker("Refresh rate:", selection: $settings.refreshRate) {
                    Text("60 Hz").tag(0)
                    Text("120 Hz").tag(1)
                }
                .pickerStyle(.segmented)
                .fixedSize()
                .frame(alignment: .leading)
                Spacer()
            }
            HStack {
                Spacer()
                Button("settings.reset") {
                    resetCompletedAlert.toggle()
                    settings.reset()
                    dismiss()
                }
                Button("OK") {
                    dismiss()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: resetCompletedAlert) { _ in
            ToastVM.shared.showToast(toastType: .notice,
                toastDetails: NSLocalizedString("settings.resetCompleted", comment: ""))
        }
        .padding()
    }
}
