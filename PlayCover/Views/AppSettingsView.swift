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

    @State var keymapping: Bool
    @State var mouseMapping: Bool
    @State var sensitivity: Float

    @State var disableTimeout: Bool
    @State var iosDeviceModel: String
    @State var refreshRate: Int
    @State var resolution: Int

    @State var resetCompletedAlert: Bool = false

    // TODO: Fix endless @State vars with @ObserableObject and @Published
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
                KeymappingView(keymapping: $keymapping, mouseMapping: $mouseMapping, sensitivity: $sensitivity)
                    .tabItem {
                        Text("Keymapping")
                    }
                GraphicsView(disableTimeout: $disableTimeout, iosDeviceModel: $iosDeviceModel, refreshRate: $refreshRate, resolution: $resolution)
                    .tabItem {
                        Text("Graphics")
                    }
                InfoView(info: app.info)
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
    @Binding var keymapping: Bool
    @Binding var mouseMapping: Bool
    @Binding var sensitivity: Float

    var body: some View {
        VStack {
            HStack {
                Toggle("Keymapping", isOn: $keymapping)
                    .help("settings.toggle.km.info")
                Toggle("Mouse mapping", isOn: $mouseMapping)
                Spacer()
            }
            HStack {
                Slider(value: $sensitivity, in: 0...100, label: {
                    Text(NSLocalizedString("settings.slider.mouseSensitivity", comment: "")
                         + String(format: "%.f", sensitivity))
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
    @Binding var disableTimeout: Bool
    @Binding var iosDeviceModel: String
    @Binding var refreshRate: Int
    @Binding var resolution: Int

    var body: some View {
        VStack {
            HStack {
                Toggle("Disable display sleep", isOn: $disableTimeout)
                Spacer()
            }.padding(.bottom)
            HStack {
                Picker("iOS device:", selection: $iosDeviceModel) {
                    Text("iPad Pro (12.9-inch) (1st gen) | A9X | 4GB").tag("iPad6,7")
                    Text("iPad Pro (12.9-inch) (3rd gen) | A12Z | 4GB").tag("iPad8,6")
                    Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag("iPad13,8")
                }
                .frame(maxWidth: 300)
                Spacer()
            }
            HStack {
                Picker("Adaptive resolution:", selection: $resolution) {
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
                Picker("Refresh rate:", selection: $refreshRate) {
                    Text("60 Hz").tag(60)
                    Text("120 Hz").tag(120)
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
    @State var info: AppInfo

    var body: some View {
        VStack {
            Text("Info")
        }
        .padding()
    }
}
