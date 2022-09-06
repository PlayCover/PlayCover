//
//  PlayAppView.swift
//  PlayCover
//

import SwiftUI

struct PlayAppView: View {
    @State var app: PlayApp
    @State var isList: Bool
    @Binding var selected: PlayApp?

    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State private var showClearCacheToast = false
    @State private var showClearPreferencesAlert = false

    @State var showImportSuccess = false
    @State var showImportFail = false

    @State private var showChangeGenshinAccount = false
    @State private var showStoreGenshinAccount = false
    @State private var showDeleteGenshinAccount = false

    var body: some View {
        PlayAppConditionalView(app: app, isList: isList, selected: $selected)
            .gesture(TapGesture(count: 2).onEnded {
                shell.removeTwitterSessionCookie()
                app.launch()
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
                    if app.info.bundleIdentifier == "com.miHoYo.GenshinImpact" {
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
                Button(action: {
                    showClearCacheAlert.toggle()
                }, label: {
                    Text("playapp.clearCache")
                })
                Button(action: {
                    showClearPreferencesAlert.toggle()
                }, label: {
                    Text("playapp.clearPreferences")
                })
                Button(action: {
                    app.deleteApp()
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
            .alert("alert.app.delete", isPresented: $showClearCacheAlert) {
                Button("button.Proceed", role: .cancel) {
                    app.container?.clear()
                    showClearCacheToast.toggle()
                }
                Button("button.Cancel", role: .cancel) { }
            }
            .alert("alert.app.preferences", isPresented: $showClearPreferencesAlert) {
                Button("button.Proceed", role: .cancel) {
                    deletePreferences(app: app.info.bundleIdentifier)
                    showClearPreferencesAlert.toggle()
                }
                Button("button.Cancel", role: .cancel) { }
            }
            .onChange(of: showClearCacheToast) { _ in
                ToastVM.shared.showToast(
                    toastType: .notice,
                    toastDetails: NSLocalizedString("alert.appCacheCleared", comment: ""))
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
}

struct PlayAppConditionalView: View {
    @State var app: PlayApp
    @State var isList: Bool
    @State var selectedBackgroundColor = Color.accentColor.opacity(0.6)
    @Binding var selected: PlayApp?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlActiveState) var controlActiveState

    var body: some View {
        if isList {
            HStack(alignment: .center, spacing: 0) {
                if let img = app.icon {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .cornerRadius(7.5)
                        .shadow(radius: 1)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                    Text(app.name)
                    Spacer()
                    Text(app.settings.info.bundleVersion)
                        .padding(.horizontal, 15)
                        .foregroundColor(.secondary)
                }
            }
            .contentShape(Rectangle())
            .onChange(of: controlActiveState) { state in
                if state == .inactive {
                    selectedBackgroundColor = .gray.opacity(0.6)
                } else {
                    selectedBackgroundColor = .accentColor.opacity(0.6)
                }
            }
            .background(selected?.info.bundleIdentifier == app.info.bundleIdentifier ?
                        selectedBackgroundColor.cornerRadius(4) : Color.clear.cornerRadius(4))
        } else {
            VStack(alignment: .center, spacing: 0) {
                if let img = app.icon {
                    VStack {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .cornerRadius(12)
                            .shadow(radius: 1, y: 1)
                        Text(app.name)
                            .font(.system(size: 12))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .onChange(of: controlActiveState) { state in
                                if state == .inactive {
                                    selectedBackgroundColor = .gray.opacity(0.6)
                                } else {
                                    selectedBackgroundColor = .accentColor.opacity(0.6)
                                }
                            }
                            .background(selected?.info.bundleIdentifier == app.info.bundleIdentifier ?
                                        selectedBackgroundColor.cornerRadius(4) : Color.clear.cornerRadius(4))
                            .frame(height: 20, alignment: .top)
                    }
                }
            }
            .frame(width: 110, height: 100)
        }
    }
}
