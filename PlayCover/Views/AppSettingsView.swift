//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI

struct AppSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State var app: PlayApp

    @State var resetCompletedAlert: Bool = false

    // TODO: Remove hardcoded strings
    // TODO: Fix adapative display backend
    var body: some View {
        VStack {
            HStack {
                if let img = app.icon {
                    Image(nsImage: img).resizable()
                        .frame(width: 33, height: 33)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
                Text("\(app.name) Settings")
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            TabView {
                KeymappingView(settings: $app.settings)
                    .tabItem {
                        Text("Keymapping")
                    }
                GraphicsView(settings: $app.settings)
                    .tabItem {
                        Text("Graphics")
                    }
                InfoView(settings: $app.settings)
                    .tabItem {
                        Text("Info")
                    }
            }
            .frame(minWidth: 450, minHeight: 200)
            HStack {
                Spacer()
                Button("settings.reset") {
                    resetCompletedAlert.toggle()
                    app.settings.reset()
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

struct KeymappingView: View {
    @Binding var settings: AppSettings

    var body: some View {
        VStack {
            HStack {
                Toggle("Keymapping", isOn: $settings.keymapping)
                    .help("settings.toggle.km.info")
                Toggle("Mouse mapping", isOn: $settings.gamingMode)
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
            Spacer()
        }
        .padding()
    }
}

struct GraphicsView: View {
    @Binding var settings: AppSettings
    @State var selection: Int = 2

    var body: some View {
        VStack {
            HStack {
                Picker("iOS device:", selection: $settings.ipadModel) {
                    Text("iPad Pro (12.9-inch) (1st gen) | A9X | 4GB").tag("iPad6,7")
                    Text("iPad Pro (12.9-inch) (3rd gen) | A12Z | 4GB").tag("iPad8,6")
                    Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag("iPad13,8")
                }
                .frame(maxWidth: 300)
                Spacer()
            }
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
            Spacer()
        }
        .padding()
    }
}

struct InfoView: View {
    @Binding var settings: AppSettings

    var body: some View {
        VStack {
            Text("Info")
        }
        .padding()
    }
}
