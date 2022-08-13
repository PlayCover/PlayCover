//
//  PlayAppView.swift
//  PlayCover
//

import Foundation
import SwiftUI
import AlertToast

struct PlayAppView: View {
    @State var app: PlayApp

    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State private var showClearCacheToast = false
    @State private var showClearPreferencesAlert = false

    @Environment(\.colorScheme) var colorScheme

    @State var isHover: Bool = false

    @State var showImportSuccess: Bool = false
    @State var showImportFail: Bool = false
    @State private var showChangeGenshinAccount: Bool = false
    @State private var showStoreGenshinAccount: Bool = false
    @State private var showDeleteGenshinAccount: Bool = false
    func elementColor(_ dark: Bool) -> Color {
        return isHover ? Color.gray.opacity(0.3) : Color.black.opacity(0.0)
    }

    var body: some View {

        VStack(alignment: .center, spacing: 0) {
            if let img = app.icon {
                Image(nsImage: img).resizable()
                    .frame(width: 88, height: 88).cornerRadius(10).shadow(radius: 1).padding(.top, 8)
                Text(app.name)
                    .frame(width: 150, height: 40)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 14)
            }
        }.background(colorScheme == .dark ? elementColor(true) : elementColor(false))
            .cornerRadius(16.0)
            .frame(width: 150, height: 150)
            .onTapGesture {
                isHover = false
                shell.removeTwitterSessionCookie()
                if app.settings.enableWindowAutoSize {
                    // Float(NSScreen.main?.visibleFrame.width ?? 1920)
                    app.settings.gameWindowSizeWidth = Float(NSScreen.main?.frame.width ?? 1920)
                    // Float(NSScreen.main?.visibleFrame.height ?? 1080)
                    app.settings.gameWindowSizeHeight = Float(NSScreen.main?.frame.height ?? 1080)
                }
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
                    app.settings.importOf { result in
                        if result != nil {
                            showImportSuccess = true
                        } else {
                            showImportFail = true
                        }
                    }
                }, label: {
                    Text("playapp.importKm")
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                })

                Button(action: {
                    app.settings.export()
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
                if app.name == "Genshin Impact" {
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
            }).sheet(isPresented: $showSettings) {
                AppSettingsView(settings: app.settings,
                                adaptiveDisplay: app.settings.adaptiveDisplay,
                                keymapping: app.settings.keymapping,
                                gamingMode: app.settings.gamingMode,
                                bypass: app.settings.bypass,
                                selectedRefreshRate: app.settings.refreshRate == 60 ? 0 : 1,
                                sensivity: app.settings.sensivity,
                                disableTimeout: app.settings.disableTimeout,
                                selectedWindowSize: app.settings.gameWindowSizeHeight == 1080
                                ? 0
                                : app.settings.gameWindowSizeHeight == 1440 ? 1 : 2,
                                enableWindowAutoSize: app.settings.enableWindowAutoSize,
                                ipadModel: app.settings.ipadModel
                ).frame(minWidth: 500)
            }.sheet(isPresented: $showChangeGenshinAccount) {
                ChangeGenshinAccountView()
            }.sheet(isPresented: $showStoreGenshinAccount) {
                StoreGenshinAccountView()
            }.sheet(isPresented: $showDeleteGenshinAccount) {
                DeleteGenshinStoredAccountView()
            }.alert("alert.app.delete", isPresented: $showClearCacheAlert) {
                Button("button.Proceed", role: .cancel) {
                    app.container?.clear()
                    showClearCacheToast.toggle()
                }
                Button("button.Cancel", role: .cancel) {}
            }.alert("alert.app.preferences", isPresented: $showClearPreferencesAlert) {
                Button("button.Proceed", role: .cancel) {
                    deletePreferences(app: app.info.bundleIdentifier)
                    showClearPreferencesAlert.toggle()
                }
                Button("button.Cancel", role: .cancel) {}
            }.toast(isPresenting: $showClearCacheToast) {
                AlertToast(type: .regular, title: "alert.appCacheCleared")
            }.toast(isPresenting: $showImportSuccess) {
                AlertToast(type: .regular, title: "alert.kmImported")
            }.toast(isPresenting: $showImportFail) {
                AlertToast(type: .regular, title: "alert.errorImportKm")
            }
    }
}
