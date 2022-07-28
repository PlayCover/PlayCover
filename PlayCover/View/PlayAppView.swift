//
//  PlayAppView.swift
//  PlayCover
//

import SwiftUI
import AlertToast

struct PlayAppView: View {

    @State var app: PlayApp

    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State private var showClearCacheToast = false

    @Environment(\.colorScheme) var colorScheme

    @State var isHover: Bool = false

    @State var showSetup: Bool = false
    @State var showImportSuccess: Bool = false
    @State var showImportFail: Bool = false

    func elementColor(_ dark: Bool) -> Color {
        return isHover ? Color.gray.opacity(0.3) : Color.black.opacity(0.0)
    }

    init(app: PlayApp) {
        _app = State(initialValue: app)
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
                app.launch()
            }
            .contextMenu {
                Button(action: {
                    showSettings.toggle()
                }, label: {
                    Text("app.settings")
                    Image(systemName: "gear")
                })

                Button(action: {
                    app.showInFinder()
                }, label: {
                    Text("app.showInFinder")
                    Image(systemName: "folder")
                })

                Button(action: {
                    app.openAppCache()
                }, label: {
                    Text("app.openCache")
                    Image(systemName: "folder")
                })

                Button(action: {
                    showClearCacheAlert.toggle()
                }, label: {
                    Text("app.clearCache")
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
                    Text("app.importkm")
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                })

                Button(action: {
                    app.settings.export()
                }, label: {
                    Text("app.exportkm")
                    Image(systemName: "arrowshape.turn.up.left")
                })

                Button(action: {
                    app.deleteApp()
                }, label: {
                    Text("app.delete")
                    Image(systemName: "trash")
                })
            }
            .onHover(perform: { hovering in
                isHover = hovering
            }).sheet(isPresented: $showSettings) {
                AppSettingsView(settings: app.settings, adaptiveDisplay: app.settings.adaptiveDisplay,
                                keymapping: app.settings.keymapping, gamingMode: app.settings.gamingMode,
                                bypass: app.settings.bypass, selectedRefreshRate:
                                    app.settings.refreshRate == 60 ? 0 : 1,
                                sensivity: app.settings.sensivity).frame(minWidth: 500)
            }.sheet(isPresented: $showSetup) {
                SetupView()
            }.alert("alert.app.delete", isPresented: $showClearCacheAlert) {
                Button("button.Proceed", role: .cancel) {
                    app.container?.clear()
                    showClearCacheToast.toggle()
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
