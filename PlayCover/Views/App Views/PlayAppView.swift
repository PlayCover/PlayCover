//
//  PlayAppView.swift
//  PlayCover
//

import SwiftUI

struct PlayAppView: View {
    @State var app: PlayApp
    @State var isList: Bool

    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State private var showClearCacheToast = false
    @State private var showClearPreferencesAlert = false

    @State var isHover: Bool = false
    @State var showImportSuccess: Bool = false
    @State var showImportFail: Bool = false

    @State private var showChangeGenshinAccount: Bool = false
    @State private var showStoreGenshinAccount: Bool = false
    @State private var showDeleteGenshinAccount: Bool = false

    var body: some View {
        PlayAppConditionalView(app: app, isList: isList, isHover: $isHover)
            .cornerRadius(10)
            .onTapGesture {
                isHover = false
                shell.removeTwitterSessionCookie()
                app.launch()
            }
            .contextMenu {
                Button(action: {
                    showSettings.toggle()
                }, label: {
                    Text("playapp.settings")
                    Image(systemName: "gear")
                })
                Button(action: {
                    app.showInFinder()
                }, label: {
                    Text("playapp.showInFinder")
                    Image(systemName: "folder")
                })
                Button(action: {
                    app.openAppCache()
                }, label: {
                    Text("playapp.openCache")
                    Image(systemName: "folder")
                })
                Button(action: {
                    showClearCacheAlert.toggle()
                }, label: {
                    Text("playapp.clearCache")
                    Image(systemName: "xmark.bin")
                })
                Button(action: {
                    showClearPreferencesAlert.toggle()
                }, label: {
                    Text("playapp.clearPreferences")
                    Image(systemName: "xmark.bin")
                })
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
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                })
                Button(action: {
                    app.keymapping.exportKeymap()
                }, label: {
                    Text("playapp.exportKm")
                    Image(systemName: "arrowshape.turn.up.left")
                })
                Button(action: {
                    app.deleteApp()
                }, label: {
                    Text("playapp.delete")
                    Image(systemName: "trash")
                })
                if app.info.bundleIdentifier == "com.miHoYo.GenshinImpact" {
                    Divider().padding(.leading, 36).padding(.trailing, 36)
                    Button(action: {
                        showStoreGenshinAccount.toggle()
                    }, label: {
                        Text("playapp.storeCurrentAccount")
                        Image(systemName: "folder.badge.person.crop")
                    })
                    Button(action: {
                        showChangeGenshinAccount.toggle()
                    }, label: {
                        Text("playapp.activateAccount")
                        Image(systemName: "folder.badge.gearshape")
                    })
                    Button(action: {
                        showDeleteGenshinAccount.toggle()
                    }, label: {
                        Text("playapp.deleteAccount")
                    Image(systemName: "folder.badge.minus")
                    })
                    Divider().padding(.leading, 36).padding(.trailing, 36)
                }
            }
            .onHover(perform: { hovering in
                isHover = hovering
            })
            .sheet(isPresented: $showChangeGenshinAccount) {
                ChangeGenshinAccountView()
            }
            .sheet(isPresented: $showStoreGenshinAccount) {
                StoreGenshinAccountView()
            }
            .sheet(isPresented: $showDeleteGenshinAccount) {
                DeleteGenshinAccountView()
            }
            .alert("alert.app.delete", isPresented: $showClearCacheAlert) {
                Button("button.Proceed", role: .cancel) {
                    app.container?.clear()
                    showClearCacheToast.toggle()
                }
                Button("button.Cancel", role: .cancel) {}
            }
            .alert("alert.app.preferences", isPresented: $showClearPreferencesAlert) {
                Button("button.Proceed", role: .cancel) {
                    deletePreferences(app: app.info.bundleIdentifier)
                    showClearPreferencesAlert.toggle()
                }
                Button("button.Cancel", role: .cancel) {}
            }
            .onChange(of: showClearCacheToast) { _ in
                ToastVM.shared.showToast(toastType: .notice,
                    toastDetails: NSLocalizedString("alert.appCacheCleared", comment: ""))
            }
            .onChange(of: showImportSuccess) { _ in
                ToastVM.shared.showToast(toastType: .notice,
                    toastDetails: NSLocalizedString("alert.kmImported", comment: ""))
            }
            .onChange(of: showImportFail) { _ in
                ToastVM.shared.showToast(toastType: .error,
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
    @Binding var isHover: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        if isList {
            HStack(alignment: .center, spacing: 0) {
                if let img = app.icon {
                    Image(nsImage: img).resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        .padding(.horizontal, 15)
                    Text(app.name)
                    Spacer()
                    Text(app.settings.info.bundleVersion)
                        .padding(.horizontal, 15)
                        .foregroundColor(.secondary)
                }
            }
            .background(
                        withAnimation {
                            isHover ? Color.gray.opacity(0.3) : Color.clear
                        }
                            .animation(.easeInOut(duration: 0.15), value: isHover)
                    )
        } else {
            VStack(alignment: .center, spacing: 0) {
                if let img = app.icon {
                    ZStack {
                        VStack {
                            Image(nsImage: img)
                                .resizable()
                        }
                        .cornerRadius(10)
                        .shadow(
                            color: isHover ? Color.black.opacity(
                                colorScheme == .dark ? 1 : 0.2
                            ) : Color.clear, radius: 13, x: 0, y: 5
                        ).animation(
                            .interpolatingSpring(
                                stiffness: 400, damping: 17
                            ), value: isHover
                        )
                        .frame(width: isHover ? 93 : 88, height: isHover ? 93 : 88)
                        .shadow(radius: 1)
                        .padding(.vertical, 5)
                        VStack {
                            Spacer()
                            HStack {
                                Text(app.name)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .frame(width: 150, height: 130)
        }
    }
}