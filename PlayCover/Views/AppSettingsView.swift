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
    @Binding var settings: AppSettings

    @State var keymapping: Bool
    @State var mouseMapping: Bool
    @State var sensitivity: Float

    @State var disableTimeout: Bool
    @State var iosDeviceModel: String
    @State var refreshRate: Int
    @State var resolution: Int

    @State var resetCompletedAlert: Bool = false

    // TODO: Fix endless @State vars with @ObserableObject and @Published
    var body: some View {
        VStack {
            HStack {
                if let img = app.icon {
                    Image(nsImage: img).resizable()
                        .frame(width: 33, height: 33)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
                Text("\(app.name) " + NSLocalizedString("settings.title", comment: ""))
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            TabView {
                KeymappingView(keymapping: $keymapping, mouseMapping: $mouseMapping, sensitivity: $sensitivity)
                    .tabItem {
                        Text("settings.tab.km")
                    }
                GraphicsView(disableTimeout: $disableTimeout, iosDeviceModel: $iosDeviceModel,
                             refreshRate: $refreshRate, resolution: $resolution)
                    .tabItem {
                        Text("settings.tab.graphics")
                    }
                JBBypassView()
                    .tabItem {
                        Text("settings.tab.jbBypass")
                    }
                InfoView(info: app.info)
                    .tabItem {
                        Text("settings.tab.info")
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
                Button("button.OK") {
                    dismiss()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: keymapping) { value in
            settings.keymapping = value
        }
        .onChange(of: mouseMapping) { value in
            settings.mouseMapping = value
        }
        .onChange(of: sensitivity) { value in
            settings.sensitivity = value
        }
        .onChange(of: disableTimeout) { value in
            settings.disableTimeout = value
        }
        .onChange(of: iosDeviceModel) { value in
            settings.iosDeviceModel = value
        }
        .onChange(of: refreshRate) { value in
            settings.refreshRate = value
        }
        .onChange(of: resolution) { value in
            settings.resolution = value
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
                Toggle("settings.toggle.km", isOn: $keymapping)
                    .help("settings.toggle.km.help")
                Toggle("settings.toggle.mm", isOn: $mouseMapping)
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
                Toggle("settings.toggle.disableDisplaySleep", isOn: $disableTimeout)
                Spacer()
            }.padding(.bottom)
            HStack {
                Picker("settings.picker.iosDevice", selection: $iosDeviceModel) {
                    Text("iPad Pro (12.9-inch) (1st gen) | A9X | 4GB").tag("iPad6,7")
                    Text("iPad Pro (12.9-inch) (3rd gen) | A12Z | 4GB").tag("iPad8,6")
                    Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag("iPad13,8")
                }
                .frame(maxWidth: 300)
                Spacer()
            }
            HStack {
                Picker("settings.picker.adaptiveRes", selection: $resolution) {
                    Text("settings.picker.adaptiveRes.0").tag(0)
                    Text("settings.picker.adaptiveRes.1").tag(1)
                    Text("1080p").tag(2)
                    Text("1440p").tag(3)
                    Text("4K").tag(4)
                }
                .fixedSize()
                .frame(alignment: .leading)
                .help("settings.picker.adaptiveRes.help")
                Spacer()
            }
            HStack {
                Picker("settings.picker.refreshRate", selection: $refreshRate) {
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

struct JBBypassView: View {
    var body: some View {
        VStack {
            Text("Jailbreak Bypass")
        }
        .padding()
    }
}

struct InfoView: View {
    @State var info: AppInfo

    var body: some View {
        List {
            HStack {
                Text("Display name:")
                Spacer()
                Text("\(info.displayName)")
            }
            HStack {
                Text("Bundle name:")
                Spacer()
                Text("\(info.bundleName)")
            }
            HStack {
                Text("Bundle identifier:")
                Spacer()
                Text("\(info.bundleIdentifier)")
            }
            HStack {
                Text("Bundle version:")
                Spacer()
                Text("\(info.bundleVersion)")
            }
            HStack {
                Text("Executable name:")
                Spacer()
                Text("\(info.executableName)")
            }
            HStack {
                Text("Minimum OS version:")
                Spacer()
                Text("\(info.minimumOSVersion)")
            }
            HStack {
                Text("URL:")
                Spacer()
                Text("\(info.url)")
            }
            HStack {
                Text("Is Game:")
                Spacer()
                Text("\(info.isGame ? "Yes" : "No")")
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
        .padding()
    }
}
