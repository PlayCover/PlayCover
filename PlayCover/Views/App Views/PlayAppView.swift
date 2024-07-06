//
//  PlayAppView.swift
//  PlayCover
//

import SwiftUI
import DataCache

struct PlayAppView: View {
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @Binding var selected: PlayApp?
    @Binding var isList: Bool

    @StateObject var viewModel: PlayAppVM

    var body: some View {
        PlayAppConditionalView(selectedBackgroundColor: $selectedBackgroundColor,
                               selectedTextColor: $selectedTextColor,
                               selected: $selected,
                               showStartingProgress: $viewModel.showStartingProgress,
                               app: viewModel.app,
                               isList: isList)
            .gesture(TapGesture(count: 2).onEnded {
                if viewModel.app.info.bundleIdentifier == "com.miHoYo.GenshinImpact" {
                    removeTwitterSessionCookie()
                }
                // Launch the app from a separate thread (allow us to Sayori it if needed)
                Task(priority: .userInitiated) {
                    if !viewModel.app.isStarting {
                        viewModel.showStartingProgress = true
                        await viewModel.app.launch()
                        viewModel.showStartingProgress = false
                    }
                }
            })
            .simultaneousGesture(TapGesture().onEnded {
                selected = viewModel.app
            })
            .contextMenu {
                Button(action: {
                    viewModel.showSettings.toggle()
                }, label: {
                    Text("playapp.settings")
                })
                Button(action: {
                    viewModel.app.openAppCache()
                }, label: {
                    Text("playapp.openCache")
                })
                Button(action: {
                    viewModel.app.showInFinder()
                }, label: {
                    Text("playapp.showInFinder")
                })
                Divider()
                Group {
                    Button(action: {
                        viewModel.app.keymapping.importKeymap { result in
                            if result {
                                viewModel.showImportSuccess.toggle()
                            } else {
                                viewModel.showImportFail.toggle()
                            }
                        }
                    }, label: {
                        Text("playapp.importKm")
                    })
                    Button(action: {
                        viewModel.app.keymapping.exportKeymap()
                    }, label: {
                        Text("playapp.exportKm")
                    })
                }
                Group {
                    if viewModel.app.info.bundleIdentifier.contains("GenshinImpact")
                        || viewModel.app.info.bundleIdentifier.contains("Yuanshen") {
                        Divider()
                        Button(action: {
                            viewModel.showStoreGenshinAccount.toggle()
                        }, label: {
                            Text("playapp.storeCurrentAccount")
                        })
                        Button(action: {
                            viewModel.showChangeGenshinAccount.toggle()
                        }, label: {
                            Text("playapp.activateAccount")
                        })
                        Button(action: {
                            viewModel.showDeleteGenshinAccount.toggle()
                        }, label: {
                            Text("playapp.deleteAccount")
                        })
                    }
                }
                Divider()
                Group {
                    Button(action: {
                        selected = nil
                        Task { await Uninstaller.clearCachePopup(viewModel.app) }
                    }, label: {
                        Text("playapp.clearCache")
                    })
                    Button(action: {
                        viewModel.showClearPreferencesAlert.toggle()
                    }, label: {
                        Text("playapp.clearPreferences")
                    })
                    Button(action: {
                        viewModel.showClearPlayChainAlert.toggle()
                    }, label: {
                        Text("playapp.clearPlayChain")
                    })
                }
                Divider()
                Button(action: {
                    selected = nil
                    Task { await Uninstaller.uninstallPopup(viewModel.app) }
                }, label: {
                    Text("playapp.delete")
                })
            }
            .sheet(isPresented: $viewModel.showChangeGenshinAccount) {
                ChangeGenshinAccountView(app: viewModel.app)
            }
            .sheet(isPresented: $viewModel.showStoreGenshinAccount) {
                StoreGenshinAccountView(app: viewModel.app)
            }
            .sheet(isPresented: $viewModel.showDeleteGenshinAccount) {
                DeleteGenshinAccountView()
            }
            .alert("alert.app.preferences", isPresented: $viewModel.showClearPreferencesAlert) {
                Button("button.Proceed", role: .destructive) {
                    deletePreferences(app: viewModel.app.info.bundleIdentifier)
                    viewModel.showClearPreferencesAlert.toggle()
                }
                Button("button.Cancel", role: .cancel) { }
            }
            .alert("alert.app.clearPlayChain", isPresented: $viewModel.showClearPlayChainAlert) {
                Button("button.Proceed", role: .destructive) {
                    viewModel.app.clearPlayChain()
                    viewModel.showClearPlayChainAlert.toggle()
                }
                Button("button.Cancel", role: .cancel) { }
            }
            .onChange(of: viewModel.showImportSuccess) { _ in
                ToastVM.shared.showToast(
                    toastType: .notice,
                    toastDetails: NSLocalizedString("alert.kmImported", comment: ""))
            }
            .onChange(of: viewModel.showImportFail) { _ in
                ToastVM.shared.showToast(
                    toastType: .error,
                    toastDetails: NSLocalizedString("alert.errorImportKm", comment: ""))
            }
            .sheet(isPresented: $viewModel.showSettings) {
                AppSettingsView(viewModel: AppSettingsVM(app: viewModel.app))
            }
    }

    func removeTwitterSessionCookie() {
        do {
            let cookieURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library")
                .appendingPathComponent("Containers")
                .appendingPathComponent("com.miHoYo.GenshinImpact")
                .appendingPathComponent("Data")
                .appendingPathComponent("Library")
                .appendingPathComponent("Cookies")
                .appendingPathComponent("Cookies")
                .appendingPathExtension("binarycookies")
            if FileManager.default.fileExists(atPath: cookieURL.path) {
                try FileManager.default.removeItem(at: cookieURL)
            }
        } catch {
            print("Error when attempting to remove Twitter session cookie: \(error)")
        }
    }

    func deletePreferences(app: String) {
        let plistURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingEscapedPathComponent(app)
            .appendingPathComponent("Data")
            .appendingPathComponent("Library")
            .appendingPathComponent("Preferences")
            .appendingEscapedPathComponent(app)
            .appendingPathExtension("plist")

        guard FileManager.default.fileExists(atPath: plistURL.path) else { return }

        do {
            try FileManager.default.removeItem(atPath: plistURL.path)
        } catch {
            Log.shared.log("\(error)", isError: true)
        }
    }
}

struct PlayAppConditionalView: View {
    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @Binding var selected: PlayApp?
    @Binding var showStartingProgress: Bool

    @State var app: PlayApp
    @State var appIcon: NSImage?
    @State var isList: Bool
    @State var hasPlayTools: Bool?

    @State private var cache = DataCache.instance

    var body: some View {
        Group {
            if isList {
                HStack(alignment: .center, spacing: 0) {
                    Group {
                        if let image = appIcon {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Rectangle()
                                 .fill(.regularMaterial)
                                 .overlay {
                                     ProgressView()
                                         .progressViewStyle(.circular)
                                         .controlSize(.small)
                                 }
                        }
                    }
                    .frame(width: 30, height: 30)
                    .cornerRadius(7.5)
                    .shadow(radius: 1)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)

                    Text(app.name)
                        .foregroundColor(selected?.url == app.url ?
                                         selectedTextColor : Color.primary)
                    if !(hasPlayTools ?? true) {
                        Image(systemName: "exclamationmark.triangle")
                            .padding(.leading, 15)
                            .help("settings.noPlayTools")
                    }
                    if showStartingProgress {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 30, height: 30)
                    }
                    Spacer()
                    Text(app.settings.info.bundleVersion)
                        .padding(.horizontal, 15)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(selected?.url == app.url ?
                            selectedBackgroundColor : Color.clear)
                        .brightness(-0.2)
                    )
            } else {
                VStack {
                    Group {
                        if let image = appIcon {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Rectangle()
                                 .fill(.regularMaterial)
                                 .overlay {
                                     ProgressView()
                                         .progressViewStyle(.circular)
                                 }
                        }
                    }
                    .cornerRadius(15)
                    .shadow(radius: 1)
                    .frame(width: 60, height: 60)

                    let noPlayToolsWarning = Text(
                        (hasPlayTools ?? true) ? "" : "\(Image(systemName: "exclamationmark.triangle"))  "
                    )
                    HStack {
                        Text("\(noPlayToolsWarning)\(app.name)")
                            .lineLimit(1)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .foregroundColor(selected?.url == app.url ?
                                             selectedTextColor : Color.primary)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(selected?.url == app.url ?
                                          selectedBackgroundColor : Color.clear)
                                    .brightness(-0.2)
                            )
                            .help(!(hasPlayTools ?? true) ? "settings.noPlayTools" : "")
                            .frame(width: 130, height: 20)
                        if showStartingProgress {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 20, height: 20)
                        }
                    }
                }
                .frame(width: 130, height: 130)
            }
        }
        .task(priority: .userInitiated) {
            let compareStr = app.info.bundleIdentifier + app.info.bundleVersion
            if cache.readImage(forKey: app.info.bundleIdentifier) != nil
                && cache.readString(forKey: compareStr) != nil {
                appIcon = cache.readImage(forKey: app.info.bundleIdentifier)
            } else {
                appIcon = Cacher().resolveLocalIcon(app)
            }
        }
        .task(priority: .background) {
            hasPlayTools = app.hasPlayTools()
            showStartingProgress = app.isStarting
        }
    }
}
