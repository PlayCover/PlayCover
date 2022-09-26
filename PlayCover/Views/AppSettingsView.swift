//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI

// swiftlint:disable file_length
struct AppSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: AppSettingsVM

    @State var resetSettingsCompletedAlert = false
    @State var resetKmCompletedAlert = false

    var body: some View {
        VStack {
            HStack {
                if let img = viewModel.app.icon {
                    Image(nsImage: img).resizable()
                        .frame(width: 33, height: 33)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
                Text(String(
                    format:
                        NSLocalizedString("settings.title", comment: ""),
                    viewModel.app.name))
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            TabView {
                KeymappingView(settings: $viewModel.settings, viewModel: viewModel)
                    .tabItem {
                        Text("settings.tab.km")
                    }
                GraphicsView(settings: $viewModel.settings)
                    .tabItem {
                        Text("settings.tab.graphics")
                    }
                JBBypassView(settings: $viewModel.settings)
                    .tabItem {
                        Text("settings.tab.jbBypass")
                    }
                MiscView(settings: $viewModel.settings)
                    .tabItem {
                        Text("settings.tab.misc")
                    }
                InfoView(info: viewModel.app.info)
                    .tabItem {
                        Text("settings.tab.info")
                    }
            }
            .frame(minWidth: 450, minHeight: 200)
            HStack {
                Spacer()
                Button("settings.resetSettings") {
                    resetSettingsCompletedAlert.toggle()
                    viewModel.app.settings.reset()
                    dismiss()
                }
                Button("settings.resetKm") {
                    resetKmCompletedAlert.toggle()
                    viewModel.app.keymapping.reset()
                    dismiss()
                }
                Button("button.OK") {
                    dismiss()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .onChange(of: resetSettingsCompletedAlert) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("settings.resetSettingsCompleted", comment: ""))
        }
        .onChange(of: resetKmCompletedAlert) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("settings.resetKmCompleted", comment: ""))
        }
        .padding()
    }
}

struct KeymappingView: View {
    struct KeymapFolder: Codable {
        var name: String
        var url: String
        var htmlUrl: String
    }

    struct KeymapInfo: Codable, Hashable {
        var name: String
        var downloadUrl: String
    }

    @Environment(\.dismiss) var dismiss

    @State private var hasKeymapping = false
    @State private var fetchedKeymapsFolder: KeymapFolder?
    @State private var fetchedKeymaps = [KeymapInfo]()
    @State private var keymappingPath: URL?
    @State private var downloadedKeymapping: Data?

    @State private var showImportSuccess = false
    @State private var showPopover = false
    @State private var keymapSelection = "Select Keymapping"

    @Binding var settings: AppSettings
    @ObservedObject var viewModel: AppSettingsVM

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Toggle("settings.toggle.km", isOn: $settings.settings.keymapping)
                        .help("settings.toggle.km.help")
                    Spacer()
                    Toggle("settings.toggle.mm", isOn: $settings.settings.mouseMapping)
                        .help("settings.toggle.mm.help")
                        .disabled(!settings.settings.keymapping)

                    if hasKeymapping {
                        Spacer()
                        Button("Download Keymapping") {
                            showPopover = true
                        }
                        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                            VStack(alignment: .center) {
                                Picker("", selection: $keymapSelection) {
                                    ForEach(fetchedKeymaps, id: \.self) { keymap in
                                        Text(keymap.name.replacingOccurrences(of: ".playmap", with: ""))
                                    }
                                }
                                Link("Keymap Info", destination: URL(string: fetchedKeymapsFolder!.htmlUrl)!)
                                Divider()
                                HStack(alignment: .center) {
                                    Button("Cancel", role: .cancel) {
                                        dismiss()
                                    }
                                    Button("Save") {
                                        Task {
                                            await downloadKeymapping(fetchedKeymaps.firstIndex(where: {
                                                $0.name == keymapSelection
                                            })!)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(width: 250, height: 150)
                        }
                    }
                }
                HStack {
                    Text(String(
                        format: NSLocalizedString("settings.slider.mouseSensitivity", comment: ""),
                        settings.settings.sensitivity))
                    Spacer()
                    Slider(value: $settings.settings.sensitivity, in: 0...100, label: { EmptyView() })
                        .frame(width: 250)
                        .disabled(!settings.settings.keymapping)
                }
                Spacer()
            }
            .padding()
        }
        .task {
            await isInKeymaps()
        }
        .onChange(of: showImportSuccess) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("alert.kmImported", comment: ""))
        }
    }

    // Check if the game currently played is in keymaps repository
    func isInKeymaps() async {
        guard let url = URL(string: "https://api.github.com/repos/PlayCover/keymaps/contents/keymapping") else {
            print("Invalid URL")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            let decodedResponse = try decoder.decode([KeymapFolder].self, from: data)

            for index in 0..<decodedResponse.count
            where decodedResponse[index].name.contains(settings.info.bundleIdentifier) {
                hasKeymapping = true
                fetchedKeymapsFolder = decodedResponse[index]

                // Get keymapping data and store it
                let (data, _) = try await URLSession.shared.data(from: URL(string: fetchedKeymapsFolder!.url)!)
                let decodedResponse = try decoder.decode([KeymapInfo].self, from: data)
                fetchedKeymaps = decodedResponse.filter {
                    $0.name.contains(".playmap")
                }

                return
            }

            hasKeymapping = false
        } catch {
            Log.shared.error(error)
        }
    }

    func downloadKeymapping(_ keymapIndex: Int) async {
        guard let url = URL(string: fetchedKeymaps[keymapIndex].downloadUrl) else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.downloadTask(with: url) { localURL, _, _ in
            if let localURL = localURL {
                keymappingPath = localURL
                if let data = try? Data(contentsOf: localURL) {
                    downloadedKeymapping = data
                    saveKeymapping()
                }
            }
        }

        task.resume()
    }

    func saveKeymapping() {
        do {
            let keymap = try PropertyListDecoder().decode(Keymap.self, from: downloadedKeymapping!)
            viewModel.app.keymapping.keymap = keymap
            showImportSuccess.toggle()
        } catch {
            if let keymap = LegacySettings.convertLegacyKeymapFile(keymappingPath!) {
                viewModel.app.keymapping.keymap = keymap
                showImportSuccess.toggle()
                return
            }

            Log.shared.error(error)
        }
    }
}

struct GraphicsView: View {
    @Binding var settings: AppSettings

    @State var customWidth = 1920
    @State var customHeight = 1080

    static var number: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("settings.picker.iosDevice")
                    Spacer()
                    Picker("", selection: $settings.settings.iosDeviceModel) {
                        Text("iPad Pro (12.9-inch) (1st gen) | A9X | 4GB").tag("iPad6,7")
                        Text("iPad Pro (12.9-inch) (3rd gen) | A12Z | 4GB").tag("iPad8,6")
                        Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag("iPad13,8")
                    }
                    .frame(width: 250)
                }
                HStack {
                    Text("settings.picker.adaptiveRes")
                    Spacer()
                    Picker("", selection: $settings.settings.resolution) {
                        Text("settings.picker.adaptiveRes.0").tag(0)
                        Text("settings.picker.adaptiveRes.1").tag(1)
                        Text("1080p").tag(2)
                        Text("1440p").tag(3)
                        Text("4K").tag(4)
                        Text("settings.picker.adaptiveRes.5").tag(5)
                    }
                    .frame(width: 250, alignment: .leading)
                    .help("settings.picker.adaptiveRes.help")
                }
                HStack {
                    if settings.settings.resolution == 5 {
                        Text(NSLocalizedString("settings.text.customWidth", comment: "") + ":")
                        Stepper {
                            TextField(
                                "settings.text.customWidth",
                                value: $customWidth,
                                formatter: GraphicsView.number,
                                onCommit: {
                                    DispatchQueue.main.async {
                                        NSApp.keyWindow?.makeFirstResponder(nil)
                                    }
                                })
                                .frame(width: 125)
                        }
                        onIncrement: {
                            customWidth += 1
                        } onDecrement: {
                            customWidth -= 1
                        }
                        Spacer()
                        Text(NSLocalizedString("settings.text.customHeight", comment: "") + ":")
                        Stepper {
                            TextField(
                                "settings.text.customHeight",
                                value: $customHeight,
                                formatter: GraphicsView.number,
                                onCommit: {
                                    DispatchQueue.main.async {
                                        NSApp.keyWindow?.makeFirstResponder(nil)
                                    }
                                })
                                .frame(width: 125)
                        } onIncrement: {
                            customHeight += 1
                        } onDecrement: {
                            customHeight -= 1
                        }
                    } else if settings.settings.resolution >= 2 && settings.settings.resolution <= 4 {
                        Text("settings.picker.aspectRatio")
                        Spacer()
                        Picker("", selection: $settings.settings.aspectRatio) {
                            Text("4:3").tag(0)
                            Text("16:9").tag(1)
                            Text("16:10").tag(2)
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                    } else if settings.settings.resolution == 1 {
                        let width = Int(NSScreen.main?.frame.width ?? 1920)
                        let height = getHeightForNotch(width, Int(NSScreen.main?.frame.height ?? 1080))
                        Text("settings.text.detectedResolution")
                        Spacer()
                        Text("\(width) x \(height)")
                    }
                }
                HStack {
                    Toggle("settings.toggle.disableDisplaySleep", isOn: $settings.settings.disableTimeout)
                        .help("settings.toggle.disableDisplaySleep.help")
                    Spacer()
                }
                Spacer()
            }
            .padding()
            .onAppear {
                customWidth = settings.settings.windowWidth
                customHeight = settings.settings.windowHeight
            }
            .onChange(of: settings.settings.resolution) { _ in
                setResolution()
            }
            .onChange(of: settings.settings.aspectRatio) { _ in
                setResolution()
            }
            .onChange(of: customWidth) { _ in
                setResolution()
            }
            .onChange(of: customHeight) { _ in
                setResolution()
            }
        }
    }

    func setResolution() {
        var width: Int
        var height: Int

        switch settings.settings.resolution {
        // Adaptive resolution = Auto
        case 1:
            width = Int(NSScreen.main?.frame.width ?? 1920)
            height = getHeightForNotch(width, Int(NSScreen.main?.frame.height ?? 1080))
        // Adaptive resolution = 1080p
        case 2:
            height = 1080
            width = getWidthFromAspectRatio(height)
        // Adaptive resolution = 1440p
        case 3:
            height = 1440
            width = getWidthFromAspectRatio(height)
        // Adaptive resolution = 4K
        case 4:
            height = 2160
            width = getWidthFromAspectRatio(height)
        // Adaptive resolution = Custom
        case 5:
            width = customWidth
            height = customHeight
        // Adaptive resolution = Off
        default:
            width = 1920
            height = 1080
        }

        settings.settings.windowWidth = width
        settings.settings.windowHeight = height
    }

    func getWidthFromAspectRatio(_ height: Int) -> Int {
        var widthRatio: Int
        var heightRatio: Int

        switch settings.settings.aspectRatio {
        case 0:
            widthRatio = 4
            heightRatio = 3
        case 1:
            widthRatio = 16
            heightRatio = 9
        case 2:
            widthRatio = 16
            heightRatio = 10
        default:
            widthRatio = 16
            heightRatio = 9
        }
        return (height / heightRatio) * widthRatio
    }
    func getHeightForNotch(_ width: Int, _ height: Int) -> Int {
        let wFloat = Float(width)
        let hFloat = Float(height)
        if NSScreen.hasNotch() && (hFloat/wFloat)*16.0 > 10.3 && (hFloat/wFloat)*16.0 < 10.4 {
            return Int((wFloat / 16) * 10)
        } else {
            return Int(height)
        }
    }
}

struct JBBypassView: View {
    @Binding var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Toggle("settings.toggle.jbBypass", isOn: $settings.settings.bypass)
                        .help("settings.toggle.jbBypass.help")
                    Spacer()
                }
            }
            .padding()
        }
    }
}

struct MiscView: View {
    @Binding var settings: AppSettings
    @State var showPopover = false

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Toggle("settings.toggle.discord", isOn: $settings.settings.discordActivity.enable)
                    Button("settings.button.discord") { showPopover = true }
                        .popover(isPresented: $showPopover, arrowEdge: .bottom) {
                            VStack {
                                HStack {
                                    Text("settings.text.applicationID")
                                        .frame(width: 90)
                                    TextField("", text: $settings.settings.discordActivity.applicationID)
                                        .frame(minWidth: 200, maxWidth: 200)
                                }.padding([.horizontal, .top])
                                HStack {
                                    Text("settings.text.details")
                                        .frame(width: 90)
                                        .help("settings.text.details.help")
                                    TextField("", text: $settings.settings.discordActivity.details)
                                        .frame(minWidth: 200, maxWidth: 200)
                                }.padding(.horizontal)
                                HStack {
                                    Text("settings.text.state")
                                        .frame(width: 90)
                                        .help("settings.text.state.help")
                                    TextField("", text: $settings.settings.discordActivity.state)
                                        .frame(minWidth: 200, maxWidth: 200)
                                }.padding(.horizontal)
                                HStack {
                                    Text("settings.text.image")
                                        .help("settings.text.image.help")
                                        .frame(width: 90)
                                    TextField("", text: $settings.settings.discordActivity.image)
                                        .frame(minWidth: 200, maxWidth: 200)
                                }.padding(.horizontal)
                                HStack {
                                    Button("settings.button.clearActivity") {
                                        settings.settings.discordActivity = DiscordActivity()
                                        showPopover = false
                                    }
                                    Button("button.OK") { showPopover = false }
                                }.padding(.bottom)
                            }
                        }
                    Spacer()
                }
                if #available(macOS 13.0, *) {
                    HStack {
                        Toggle("settings.toggle.hud", isOn: $settings.metalHudEnabled)
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct InfoView: View {
    @State var info: AppInfo

    var body: some View {
        List {
            HStack {
                Text("settings.info.displayName")
                Spacer()
                Text("\(info.displayName)")
            }
            HStack {
                Text("settings.info.bundleName")
                Spacer()
                Text("\(info.bundleName)")
            }
            HStack {
                Text("settings.info.bundleIdentifier")
                Spacer()
                Text("\(info.bundleIdentifier)")
            }
            HStack {
                Text("settings.info.bundleVersion")
                Spacer()
                Text("\(info.bundleVersion)")
            }
            HStack {
                Text("settings.info.executableName")
                Spacer()
                Text("\(info.executableName)")
            }
            HStack {
                Text("settings.info.minimumOSVersion")
                Spacer()
                Text("\(info.minimumOSVersion)")
            }
            HStack {
                Text("settings.info.url")
                Spacer()
                Text("\(info.url.relativePath)")
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
        .padding()
    }
}
