//
//  MiscSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI

struct MiscView: View {
    @Environment(AppsVM.self) private var apps
    @Binding var settings: AppSettings
    @Binding var closeView: Bool
    @Binding var hasPlayTools: Bool?
    @Binding var hasAlias: Bool?
    @Binding var task: BlockingTask
    @AppStorage("settings.settings.discordActivity.enable") private var discordActivity = false
    @AppStorage("settings.settings.metalHUD") private var metalHUD = false
    @AppStorage("settings.openWithLLDB") private var openWithLLDB = false
    @AppStorage("settings.openLLDBWithTerminal") private var openLLDBWithTerminal = false
    @AppStorage("settings.customPluginsWarningShown") private var hasShownCustomPluginWarning = false
    @State var showPopover = false
    @State private var userDylibs: [URL] = []
    @State private var showCustomPluginWarning = false
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
                    .onChange(of: applicationCategoryType) {
                        task = .applicationCategoryType
                        app.info.applicationCategoryType = applicationCategoryType
                        Task {
                            await AppSigner.reseal(app)
                            task = .none
                        }
                    }
                }
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
                HStack {
                    HStack {
                        Toggle("settings.toggle.hud", isOn: $settings.settings.metalHUD)
                        Spacer()
                        HStack {
                            Text("settings.text.debugger")
                            VStack(alignment: .leading) {
                                HStack {
                                    Toggle("", isOn: $settings.openWithLLDB)
                                        .labelsHidden()
                                    Text("settings.toggle.lldb")
                                }

                                HStack {
                                    Toggle("", isOn: $settings.openLLDBWithTerminal)
                                        .labelsHidden()
                                        .disabled(!settings.openWithLLDB)
                                    Text("settings.toggle.lldbWithTerminal")
                                }
                            }
                        }
                    }
                }
                HStack {
                    Toggle("settings.toggle.rootWorkDir", isOn: $settings.settings.rootWorkDir)
                        .disabled(!(hasPlayTools ?? true))
                        .help("settings.toggle.rootWorkDir.help")
                    Spacer()
                }
                HStack {
                    Toggle("settings.toggle.limitMotionUpdateFrequency",
                           isOn: $settings.settings.limitMotionUpdateFrequency)
                        .disabled(!(hasPlayTools ?? true))
                        .help("settings.toggle.limitMotionUpdateFrequency.help")
                    Spacer()
                }
                HStack {
                    Toggle("settings.toggle.ignoreUnityKeyboardInitializationError",
                           isOn: $settings.settings.ignoreUnityKeyboardInitializationError)
                        .disabled(!(hasPlayTools ?? true))
                        .help("settings.toggle.ignoreUnityKeyboardInitializationError.help")
                    Spacer()
                }
                CustomDylibView(app: app,
                                showCustomPluginWarning: $showCustomPluginWarning,
                                hasShownCustomPluginWarning: $hasShownCustomPluginWarning,
                                hasPlayTools: $hasPlayTools,
                                userDylibs: $userDylibs)
                HStack {
                    Spacer()
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

                            apps.filteredApps = []
                            apps.fetchApps()

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
                    .buttonStyle(.borderedProminent).tint(Color.red)
                }
            }
            .padding()
        }
    }

}

struct CustomDylibView: View {
    var app: PlayApp
    @Binding var showCustomPluginWarning: Bool
    @Binding var hasShownCustomPluginWarning: Bool
    @Binding var hasPlayTools: Bool?
    @Binding var userDylibs: [URL]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("settings.customPlugins.title")
                    .font(.headline)
                Spacer()
                Button {
                    if hasShownCustomPluginWarning {
                        selectAndAddDylib()
                    } else {
                        showCustomPluginWarning = true
                    }
                } label: {
                    Label("settings.customPlugins.add", systemImage: "plus")
                }
            }
            if userDylibs.isEmpty {
                Text("settings.customPlugins.empty")
                    .foregroundColor(.secondary)
                    .font(.caption)
            } else {
                ForEach(userDylibs, id: \.self) { dylib in
                    HStack {
                        Text(dylib.lastPathComponent)
                        Spacer()
                        Button {
                            removeDylib(dylib)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .disabled(!(hasPlayTools ?? true))
        .onAppear {
            reloadUserDylibs()
        }
        .alert("settings.customPlugins.warningTitle", isPresented: $showCustomPluginWarning) {
            Button("button.Cancel", role: .cancel) {}
            Button("settings.customPlugins.warningConfirm", role: .destructive) {
                hasShownCustomPluginWarning = true
                selectAndAddDylib()
            }
        } message: {
            Text("settings.customPlugins.warningMessage")
        }
    }
    private func reloadUserDylibs() {
        userDylibs = PlayTools.userDylibs(bundleIdentifier: app.info.bundleIdentifier)
    }

    private func selectAndAddDylib() {
        NSOpenPanel.selectDylib { result in
            guard case .success(let url) = result else { return }
            let bundleIdentifier = app.info.bundleIdentifier
            let executable = app.executable
            Task {
                do {
                    // Copies, converts and signs the dylib; keep it off the main actor.
                    try await Task.detached(priority: .userInitiated) {
                        try PlayTools.addUserDylib(at: url, bundleIdentifier: bundleIdentifier,
                                                   appExecutable: executable)
                    }.value
                } catch {
                    Log.shared.error(error)
                }
                reloadUserDylibs()
            }
        }
    }

    private func removeDylib(_ url: URL) {
        let name = url.lastPathComponent
        let bundleIdentifier = app.info.bundleIdentifier
        let executable = app.executable
        Task {
            do {
                try await Task.detached(priority: .userInitiated) {
                    try PlayTools.removeUserDylib(named: name, bundleIdentifier: bundleIdentifier,
                                                  appExecutable: executable)
                }.value
            } catch {
                Log.shared.error(error)
            }
            reloadUserDylibs()
        }
    }

}
