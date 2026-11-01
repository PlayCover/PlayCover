//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI

enum BlockingTask {
    case none, playTools, introspection, iosFrameworks, applicationCategoryType
}

struct AppSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(ToastVM.self) private var toasts

    @Bindable var viewModel: AppSettingsVM

    @Binding var showKeymapSheet: Bool

    @State var resetSettingsCompletedAlert = false
    @State var closeView = false
    @State var appIcon: NSImage?
    @State var hasPlayTools: Bool?
    @State var hasAlias: Bool?

    @State private var currentTask = BlockingTask.none

    var body: some View {
        VStack {
            HStack {
                Group {
                    if let image = appIcon {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFit()
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
                appIcon = Cacher.shared.cachedIcon(bundleIdentifier: viewModel.app.info.bundleIdentifier)
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
                Button("playapp.keymap") {
                    closeView.toggle()
                    showKeymapSheet.toggle()
                }
                Button("button.OK") {
                    closeView.toggle()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .disabled(currentTask != .none)
        .onChange(of: resetSettingsCompletedAlert) {
            toasts.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("settings.resetSettingsCompleted", comment: ""))
        }
        .onChange(of: closeView) {
            dismiss()
        }
        .task(priority: .background) {
            hasPlayTools = viewModel.app.hasPlayTools()
            hasAlias = viewModel.app.hasAlias()
        }
        .padding()
        .frame(height: 400)
    }
}
