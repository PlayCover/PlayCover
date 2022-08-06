//
//  PlayAppView.swift
//  PlayCover
//

import Foundation
import SwiftUI

struct PlayAppView: View {
    @State var app: PlayApp
    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State var isHover: Bool = false
    @State var showImportSuccess: Bool = false
    @State var showImportFail: Bool = false

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
        }.background(isHover ? .gray : .clear)
            .cornerRadius(16.0)
            .frame(width: 150, height: 150)
            .onTapGesture {
                isHover = false
                shell.removeTwitterSessionCookie()
                if app.settings.enableWindowAutoSize {
                    app.settings.gameWindowSizeWidth = Float(NSScreen.main?.visibleFrame.width ?? 1920)
                    app.settings.gameWindowSizeHeight = Float(NSScreen.main?.visibleFrame.height ?? 1080)
                }
                app.launch()
            }
            .contextMenu {
                PlayAppContextMenuView(app: $app, showSettings: $showSettings,
                                       showClearCacheAlert: $showClearCacheAlert,
                                       showImportSuccess: $showImportSuccess,
                                       showImportFail: $showImportFail)
            }
            .onHover(perform: { hovering in
                isHover = hovering
            }).alert("alert.app.delete", isPresented: $showClearCacheAlert) {
                Button("button.Proceed", role: .cancel) {
                    app.container?.clear()
                }
                Button("button.Cancel", role: .cancel) {}
            }
            // TODO: Toast
            /*.toast(isPresenting: $showClearCacheToast) {
                AlertToast(type: .regular, title: "alert.appCacheCleared")
            }.toast(isPresenting: $showImportSuccess) {
                AlertToast(type: .regular, title: "alert.kmImported")
            }.toast(isPresenting: $showImportFail) {
                AlertToast(type: .regular, title: "alert.errorImportKm")
            }*/
    }
}

struct PlayAppListView: View {
    @State var app: PlayApp
    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State var isHover: Bool = false
    @State var showImportSuccess: Bool = false
    @State var showImportFail: Bool = false

    init(app: PlayApp) {
        _app = State(initialValue: app)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if let img = app.icon {
                Image(nsImage: img).resizable()
                    .frame(width: 40, height: 40).cornerRadius(10).shadow(radius: 1).padding()
                Text(app.name)
                    .frame(maxWidth: .infinity)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)
                    .padding()
            }
        }.background(isHover ? .gray : .clear)
            .cornerRadius(16)
            .frame(maxWidth: .infinity)
            .onTapGesture {
                isHover = false
                shell.removeTwitterSessionCookie()
                if app.settings.enableWindowAutoSize {
                    app.settings.gameWindowSizeWidth = Float(NSScreen.main?.visibleFrame.width ?? 1920)
                    app.settings.gameWindowSizeHeight = Float(NSScreen.main?.visibleFrame.height ?? 1080)
                }
                app.launch()
            }
            .contextMenu {
                PlayAppContextMenuView(app: $app, showSettings: $showSettings,
                                       showClearCacheAlert: $showClearCacheAlert,
                                       showImportSuccess: $showImportSuccess,
                                       showImportFail: $showImportFail)
            }
            .onHover(perform: { hovering in
                isHover = hovering
            }).alert("alert.app.delete", isPresented: $showClearCacheAlert) {
                Button("button.Proceed", role: .cancel) {
                    app.container?.clear()
                }
                Button("button.Cancel", role: .cancel) {}
            }
    }
}

struct PlayAppContextMenuView: View {
    @Binding var app: PlayApp
    @Binding var showSettings: Bool
    @Binding var showClearCacheAlert: Bool
    @Binding var showImportSuccess: Bool
    @Binding var showImportFail: Bool

    var body: some View {
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
    }
}
