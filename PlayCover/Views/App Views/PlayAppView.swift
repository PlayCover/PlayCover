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
    @State var isHover: Bool = false
    @State var showImportSuccess: Bool = false
    @State var showImportFail: Bool = false

    var body: some View {
        ConditionalView(app: app, isList: isList)
        .background(
            isHover ? Color.gray.opacity(0.3) : Color.clear
        )
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
                app.settings.importOf { result in
                    if result != nil {
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
        }
        .onHover(perform: { hovering in
            isHover = hovering
        })
        .alert("alert.app.delete", isPresented: $showClearCacheAlert) {
            Button("button.Proceed", role: .cancel) {
                app.container?.clear()
                showClearCacheToast.toggle()
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
            AppSettingsView(app: $app,
                            keymapping: $app.settings.keymapping,
                            mouseMapping: $app.settings.mouseMapping,
                            sensitivity: $app.settings.sensitivity,
                            disableTimeout: $app.settings.disableTimeout,
                            iosDeviceModel: $app.settings.iosDeviceModel,
                            refreshRate: $app.settings.refreshRate,
                            resolution: $app.settings.resolution)
        }
    }
}

struct ConditionalView: View {
    @State var app: PlayApp
    @State var isList: Bool

    var body: some View {
        if isList {
            HStack(alignment: .center, spacing: 0) {
                if let img = app.icon {
                    Image(nsImage: img).resizable()
                        .frame(width: 40, height: 40)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    Spacer()
                        .frame(width: 20)
                    Text(app.name)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
        } else {
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
            }
            .frame(width: 150, height: 150)
        }
    }
}
