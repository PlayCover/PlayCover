//
//  BypassesSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI

struct BypassesView: View {
    @Binding var settings: AppSettings
    @Binding var hasPlayTools: Bool?
    @Binding var task: BlockingTask
    @AppStorage("settings.settings.playChain") private var playChain = false
    @AppStorage("settings.settings.playChainDebugging") private var playChainDebugging = false
    @AppStorage("settings.settings.bypass") private var bypass = false
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
                Spacer()
                HStack {
                    Toggle("settings.toggle.checkMicPermissionSync", isOn: $settings.settings.checkMicPermissionSync)
                        .help("settings.toggle.checkMicPermissionSync.help")
                    Spacer()
                }
                Spacer()
                HStack {
                    Toggle("settings.toggle.blockSleepSpamming", isOn: $settings.settings.blockSleepSpamming)
                        .help("settings.toggle.blockSleepSpamming.help")
                    Spacer()
                }
            }
            .padding()
        }
        .onChange(of: hasIntrospection) {
            task = .introspection
            Task {
                _ = await AppSigner.setDyldLibraryPath(app, enabled: hasIntrospection, path: PlayApp.introspection)
                task = .none
            }
        }
        .onChange(of: hasIosFrameworks) {
            task = .iosFrameworks
            Task {
                _ = await AppSigner.setDyldLibraryPath(app, enabled: hasIosFrameworks, path: PlayApp.iosFrameworks)
                task = .none
            }
        }
    }
}
