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

    @State var app: PlayApp
    @State var isList: Bool

    @State private var showSettings = false
    @State private var showClearPreferencesAlert = false
    @State private var showClearPlayChainAlert = false

    @State var showImportSuccess = false
    @State var showImportFail = false

    @State private var showChangeGenshinAccount = false
    @State private var showStoreGenshinAccount = false
    @State private var showDeleteGenshinAccount = false

    var body: some View {
        PlayAppConditionalView(selectedBackgroundColor: $selectedBackgroundColor,
                               selectedTextColor: $selectedTextColor,
                               selected: $selected,
                               app: app,
                               isList: isList)
            .gesture(TapGesture(count: 2).onEnded {
                if app.info.bundleIdentifier == "com.miHoYo.GenshinImpact" {
                    removeTwitterSessionCookie()
                }
                // Launch the app from a separate thread (allow us to Sayori it if needed)
                Task(priority: .userInitiated) {
                    if !app.isStarting { await app.launch() }
                }
            })
            .simultaneousGesture(TapGesture().onEnded {
                selected = app
            })
            .contextMenu {
                Button(action: {
                    showSettings.toggle()
                }, label: {
                    Text("playapp.settings")
                })
                Button(action: {
                    app.openAppCache()
                }, label: {
                    Text("playapp.openCache")
                })
                Button(action: {
                    app.showInFinder()
                }, label: {
                    Text("playapp.showInFinder")
                })
                Divider()
                Group {
                    Button(action: {
                        app.keymapping.importKeymap { result in
                            if result {
                                showImportSuccess.toggle()
                            } else {
                                showImportFail.toggle()
                            }
                        }
                    }, label: {
                        Text("playapp.importKm")
                    })
                    Button(action: {
                        app.keymapping.exportKeymap()
                    }, label: {
                        Text("playapp.exportKm")
                    })
                }
                Group {
                    if app.info.bundleIdentifier.contains("GenshinImpact")
                        || app.info.bundleIdentifier.contains("Yuanshen") {
                        Divider()
                        Button(action: {
                            showStoreGenshinAccount.toggle()
                        }, label: {
                            Text("playapp.storeCurrentAccount")
                        })
                        Button(action: {
                            showChangeGenshinAccount.toggle()
                        }, label: {
                            Text("playapp.activateAccount")
                        })
                        Button(action: {
                            showDeleteGenshinAccount.toggle()
                        }, label: {
                            Text("playapp.deleteAccount")
                        })
                    }
                }
                Divider()
                Group {
                    Button(action: {
                        selected = nil
                        Task { await Uninstaller.clearCachePopup(app) }
                    }, label: {
                        Text("playapp.clearCache")
                    })
                    Button(action: {
                        showClearPreferencesAlert.toggle()
                    }, label: {
                        Text("playapp.clearPreferences")
                    })
                    Button(action: {
                        showClearPlayChainAlert.toggle()
                    }, label: {
                        Text("playapp.clearPlayChain")
                    })
                }
                Divider()
                Button(action: {
                    selected = nil
                    Task { await Uninstaller.uninstallPopup(app) }
                }, label: {
                    Text("playapp.delete")
                })
            }
            .sheet(isPresented: $showChangeGenshinAccount) {
                ChangeGenshinAccountView(app: app)
            }
            .sheet(isPresented: $showStoreGenshinAccount) {
                StoreGenshinAccountView(app: app)
            }
            .sheet(isPresented: $showDeleteGenshinAccount) {
                DeleteGenshinAccountView()
            }
            .alert("alert.app.preferences", isPresented: $showClearPreferencesAlert) {
                Button("button.Proceed", role: .destructive) {
                    deletePreferences(app: app.info.bundleIdentifier)
                    showClearPreferencesAlert.toggle()
                }
                Button("button.Cancel", role: .cancel) { }
            }
            .alert("alert.app.clearPlayChain", isPresented: $showClearPlayChainAlert) {
                Button("button.Proceed", role: .destructive) {
                    app.clearPlayChain()
                    showClearPlayChainAlert.toggle()
                }
                Button("button.Cancel", role: .cancel) { }
            }
            .onChange(of: showImportSuccess) { _ in
                ToastVM.shared.showToast(
                    toastType: .notice,
                    toastDetails: NSLocalizedString("alert.kmImported", comment: ""))
            }
            .onChange(of: showImportFail) { _ in
                ToastVM.shared.showToast(
                    toastType: .error,
                    toastDetails: NSLocalizedString("alert.errorImportKm", comment: ""))
            }
            .sheet(isPresented: $showSettings) {
                AppSettingsView(viewModel: AppSettingsVM(app: app))
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
        }
    }
}
