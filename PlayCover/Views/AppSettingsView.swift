//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI
import DataCache

enum BlockingTask {
    case none, playTools, introspection, iosFrameworks, applicationCategoryType
}

// swiftlint:disable file_length
struct AppSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var viewModel: AppSettingsVM

    @State var resetSettingsCompletedAlert = false
    @State var resetKmCompletedAlert = false
    @State var closeView = false
    @State var appIcon: NSImage?
    @State var hasPlayTools: Bool?
    @State var hasAlias: Bool?

    @State private var currentTask = BlockingTask.none
    @State private var cache = DataCache.instance

    var body: some View {
        VStack {
            HStack {
                Group {
                    if let image = appIcon {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 60, height: 60)
                    }
                }
                .cornerRadius(10)
                .shadow(radius: 1)
                .frame(width: 33, height: 33)

                VStack {
                    HStack {
                        Text(String(
                            format:
                                NSLocalizedString("settings.title", comment: ""),
                            viewModel.app.name))
                            .font(.title2).bold()
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }

                    let noPlayToolsWarning = Image(systemName: "exclamationmark.triangle")
                    let warning = NSLocalizedString("settings.noPlayTools", comment: "")

                    if !(hasPlayTools ?? true) {
                        HStack {
                            Text("\(noPlayToolsWarning) \(warning)")
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                            Spacer()
                        }
                    }
                }
            }
            .task(priority: .userInitiated) {
                appIcon = cache.readImage(forKey: viewModel.app.info.bundleIdentifier)
            }

            TabView {
                KeymappingView(settings: $viewModel.settings)
                    .tabItem {
                        Text("settings.tab.km")
                    }
                    .disabled(!(hasPlayTools ?? true))
                GraphicsView(settings: $viewModel.settings)
                    .tabItem {
                        Text("settings.tab.graphics")
                    }
                    .disabled(!(hasPlayTools ?? true))
                BypassesView(settings: $viewModel.settings,
                             hasPlayTools: $hasPlayTools,
                             task: $currentTask,
                             app: viewModel.app)
                    .tabItem {
                        Text("settings.tab.bypasses")
                    }
                    .disabled(!(hasPlayTools ?? true))
                MiscView(settings: $viewModel.settings,
                         closeView: $closeView,
                         hasPlayTools: $hasPlayTools,
                         hasAlias: $hasAlias,
                         task: $currentTask,
                         app: viewModel.app,
                         applicationCategoryType: viewModel.app.info.applicationCategoryType)
                    .tabItem {
                        Text("settings.tab.misc")
                    }
                InfoView(info: viewModel.app.info, hasPlayTools: (hasPlayTools ?? true))
                    .tabItem {
                        Text("settings.tab.info")
                    }
            }
            .frame(minWidth: 500, minHeight: 250)
            HStack {
                Spacer()
                Button("settings.resetSettings") {
                    resetSettingsCompletedAlert.toggle()
                    viewModel.app.settings.reset()
                    closeView.toggle()
                }
                Button("settings.resetKm") {
                    resetKmCompletedAlert.toggle()
                    viewModel.app.keymapping.reset()
                    closeView.toggle()
                }
                Button("button.OK") {
                    closeView.toggle()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(currentTask != .none)
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
        .onChange(of: closeView) { _ in
            dismiss()
        }
        .task(priority: .background) {
            hasPlayTools = viewModel.app.hasPlayTools()
            hasAlias = viewModel.app.hasAlias()
        }
        .padding()
    }
}

struct KeymappingView: View {
    @Binding var settings: AppSettings

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Toggle("settings.toggle.km", isOn: $settings.settings.keymapping)
                        .help("settings.toggle.km.help")
                    Spacer()
                    Toggle("settings.toggle.autoKM", isOn: $settings.settings.noKMOnInput)
                        .help("settings.toggle.autoKM.help")
                }
                HStack {
                    Toggle("settings.toggle.enableScrollWheel", isOn: $settings.settings.enableScrollWheel)
                        .help("settings.toggle.enableScrollWheel.help")
                    Spacer()
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
    }
}

struct GraphicsView: View {
    @Binding var settings: AppSettings

    @State var customWidth = 1920
    @State var customHeight = 1080

    @State var showResolutionWarning = false

    static var number: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }

    @State var customScaler = 2.0
    static var fractionFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.decimalSeparator = "."
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
                        Text("iPad Pro (12.9-inch) (3rd gen) | A12X | 4GB").tag("iPad8,6")
                        Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag("iPad13,8")
                        Text("iPad Pro (12.9-inch) (6th gen) | M2 | 8GB").tag("iPad14,5")
                        Divider()
                        Text("iPhone 13 Pro Max | A15 | 6GB").tag("iPhone14,3")
                        Text("iPhone 14 Pro Max | A16 | 6GB").tag("iPhone15,3")
                    }
                    .frame(width: 250)
                }
                HStack {
                    if showResolutionWarning {
                        Spacer()
                        let highResIcon = Image(systemName: "exclamationmark.triangle")
                        let warning = NSLocalizedString("settings.highResolution", comment: "")

                        Text("\(highResIcon) \(warning)")
                            .font(.caption)
                    } else {
                        Spacer()
                    }
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
                                    Task { @MainActor in
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
                                    Task { @MainActor in
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
                    } else {
                        Spacer()
                    }
                }
                HStack {
                    Text("settings.picker.scaler")
                    Spacer()
                    Stepper {
                        TextField(
                            "settings.text.scaler",
                            value: $customScaler,
                            formatter: GraphicsView.fractionFormatter,
                            onCommit: {
                                Task { @MainActor in
                                    NSApp.keyWindow?.makeFirstResponder(nil)
                                }
                            })
                            .frame(width: 125)
                    } onIncrement: {
                        customScaler += 0.1
                    } onDecrement: {
                        if customScaler > 0.5 {
                            customScaler -= 0.1
                        }
                    }
                }
                VStack(alignment: .leading) {
                    if #available(macOS 13.2, *) {
                        HStack {
                            Toggle("settings.picker.windowFix", isOn: $settings.settings.inverseScreenValues)
                                .help("settings.picker.windowFix.help")
                                .onChange(of: settings.settings.inverseScreenValues) { _ in
                                    settings.settings.windowFixMethod = 0
                                }
                            Spacer()
                            // Dropdown to choose fix method
                            Picker("", selection: $settings.settings.windowFixMethod) {
                                Text("settings.picker.windowFixMethod.0").tag(0)
                                Text("settings.picker.windowFixMethod.1").tag(1)
                            }
                            .frame(alignment: .leading)
                            .help("settings.picker.windowFixMethod.help")
                            .disabled(!settings.settings.inverseScreenValues)
                            .disabled(settings.settings.resolution != 0)
                        }
                        Spacer()
                    }
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
                customScaler = settings.settings.customScaler
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
            .onChange(of: customScaler) { _ in
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
            height = 1080
            width = 1920
        }

        settings.settings.windowWidth = width
        settings.settings.windowHeight = height
        settings.settings.customScaler = customScaler

        showResolutionWarning = Double(width * height) * customScaler >= 2621440 * 2.0
        // Tends to crash when the number of pixels exceeds that
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

struct BypassesView: View {
    @Binding var settings: AppSettings
    @Binding var hasPlayTools: Bool?
    @Binding var task: BlockingTask

    @State private var hasIntrospection: Bool
    @State private var hasIosFrameworks: Bool

    var app: PlayApp

    init(settings: Binding<AppSettings>,
         hasPlayTools: Binding<Bool?>,
         task: Binding<BlockingTask>,
         app: PlayApp) {
        self._settings = settings
        self._hasPlayTools = hasPlayTools
        self._task = task
        self.app = app

        let lsEnvironment = app.info.lsEnvironment["DYLD_LIBRARY_PATH"] ?? ""
        self.hasIntrospection = lsEnvironment.contains(PlayApp.introspection)
        self.hasIosFrameworks = lsEnvironment.contains(PlayApp.iosFrameworks)
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack(alignment: .center) {
                    Toggle("settings.playChain.enable", isOn: $settings.settings.playChain)
                        .help("settings.playChain.help")
                        .disabled(!(hasPlayTools ?? true))
                    Spacer()
                    Toggle("settings.playChain.debugging", isOn: $settings.settings.playChainDebugging)
                        .disabled(!settings.settings.playChain)
                }
                Spacer()
                    .frame(height: 20)
                HStack {
                    Toggle("settings.toggle.jbBypass", isOn: $settings.settings.bypass)
                        .help("settings.toggle.jbBypass.help")
                    Spacer()
                }
                Spacer()
                HStack {
                    Toggle("settings.toggle.introspection", isOn: $hasIntrospection)
                        .help("settings.toggle.introspection.help")
                        .toggleStyle(.async($task, role: .introspection))
                    Spacer()
                }
                Spacer()
                HStack {
                    Toggle("settings.toggle.iosFrameworks", isOn: $hasIosFrameworks)
                        .help("settings.toggle.iosFrameworks.help")
                        .toggleStyle(.async($task, role: .iosFrameworks))
                    Spacer()
                }
            }
            .padding()
        }
        .onChange(of: hasIntrospection) {_ in
            task = .introspection
            Task {
                _ = await app.changeDyldLibraryPath(set: hasIntrospection, path: PlayApp.introspection)
                task = .none
            }
        }
        .onChange(of: hasIosFrameworks) {_ in
            task = .iosFrameworks
            Task {
                _ = await app.changeDyldLibraryPath(set: hasIosFrameworks, path: PlayApp.iosFrameworks)
                task = .none
            }
        }
    }
}

struct MiscView: View {
    @Binding var settings: AppSettings
    @Binding var closeView: Bool
    @Binding var hasPlayTools: Bool?
    @Binding var hasAlias: Bool?
    @Binding var task: BlockingTask

    @State var showPopover = false

    var app: PlayApp

    @State var applicationCategoryType: LSApplicationCategoryType

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("settings.applicationCategoryType")
                    Spacer()
                    if task == .applicationCategoryType {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                    }
                    Picker("", selection: $applicationCategoryType) {
                        ForEach(LSApplicationCategoryType.allCases, id: \.rawValue) { value in
                            Text(value.localizedName)
                                .tag(value)
                        }
                    }
                    .frame(width: 225)
                    .onChange(of: applicationCategoryType) { _ in
                        task = .applicationCategoryType
                        app.info.applicationCategoryType = applicationCategoryType
                        Task.detached {
                            do {
                                try Shell.signApp(app.executable)
                                task = .none
                            } catch {
                                Log.shared.error(error)
                            }
                        }
                    }
                }
                Spacer()
                    .frame(height: 20)
                HStack {
                    Toggle("settings.toggle.discord", isOn: $settings.settings.discordActivity.enable)
                    Spacer()
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
                }.disabled(!(hasPlayTools ?? true))
                Spacer()
                    .frame(height: 20)
                HStack {
                    HStack {
                        Toggle("settings.toggle.hud", isOn: $settings.settings.metalHUD)
                            .disabled(!isVenturaGreater())
                            .help(!isVenturaGreater() ? "settings.unavailable.hud" : "")
                        Spacer()
                        HStack {
                            Text("settings.text.debugger")
                            VStack {
                                Toggle("settings.toggle.lldb", isOn: $settings.openWithLLDB)
                                Toggle("settings.toggle.lldbWithTerminal", isOn: $settings.openLLDBWithTerminal)
                                    .disabled(!settings.openWithLLDB)
                            }
                        }
                    }
                }
                Spacer()
                    .frame(height: 20)
                HStack {
                    Button {
                        task = .playTools
                        Task(priority: .userInitiated) {
                            if hasPlayTools ?? true {
                                await PlayTools.removeFromApp(app.executable)
                            } else {
                                do {
                                    try await PlayTools.installInIPA(app.executable)
                                } catch {
                                    Log.shared.error(error)
                                }
                            }

                            Task { @MainActor in
                                AppsVM.shared.filteredApps = []
                                AppsVM.shared.fetchApps()
                            }

                            task = .none
                            closeView.toggle()
                        }
                    } label: {
                        Text((hasPlayTools ?? true) ? "settings.removePlayTools" : "alert.install.injectPlayTools")
                            .opacity(task == .playTools ? 0 : 1)
                            .overlay {
                                if task == .playTools {
                                    ProgressView().scaleEffect(0.5)
                                }
                            }
                    }
                    Spacer()
                }
                Spacer()
                    .frame(height: 20)
                // swiftlint:disable:next todo
                // TODO: Test and remove before 3.0 release
                HStack {
                    Toggle("settings.toggle.rootWorkDir", isOn: $settings.settings.rootWorkDir)
                        .disabled(!(hasPlayTools ?? true))
                        .help("settings.toggle.rootWorkDir.help")
                    Spacer()
                }
            }
            .padding()
        }
    }

    func isVenturaGreater() -> Bool {
        if #available(macOS 13.0, *) {
            return true
        } else {
            return false
        }
    }
}

struct InfoView: View {
    @State var info: AppInfo
    @State var hasPlayTools: Bool

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
                Text("settings.applicationCategoryType") + Text(":")
                Spacer()
                Text("\(info.applicationCategoryType.rawValue)")
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
                Text("settings.info.playTools")
                Spacer()
                Text(String(hasPlayTools))
            }
            HStack {
                Text("settings.info.url")
                Spacer()
                Text("\(info.url.relativePath)")
            }
            HStack {
                Text("settings.info.alias")
                Spacer()
                Text("\(PlayApp.aliasDirectory.appendingPathComponent(info.bundleIdentifier))")
            }
        }
        .listStyle(.bordered(alternatesRowBackgrounds: true))
        .padding()
    }
}

struct AsyncToggleStyle: ToggleStyle {
    @Binding var task: BlockingTask

    var role: BlockingTask

    func makeBody(configuration: Configuration) -> some View {
        if task == role {
            return AnyView(
                HStack(spacing: 3) {
                    ProgressView()
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)

                    configuration.label
                }
            )
        } else {
            return AnyView(
                Toggle(isOn: configuration.$isOn) { configuration.label }
            )
        }
    }
}

extension ToggleStyle where Self == AsyncToggleStyle {
    static func async(_ task: Binding<BlockingTask>, role: BlockingTask) -> AsyncToggleStyle {
        AsyncToggleStyle(task: task, role: role)
    }
}
