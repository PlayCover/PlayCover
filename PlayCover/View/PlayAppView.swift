//
//  PlayAppView.swift
//  PlayCover
//

import Foundation
import SwiftUI
import AlertToast

struct PlayAppView : View {
    
    @State var app: PlayApp
    
    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State private var showClearCacheToast = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var isHover : Bool = false
    
    @State var showSetup : Bool = false
    @State var showImportSuccess : Bool = false
    @State var showImportFail : Bool = false
    
    func elementColor(_ dark : Bool) -> Color {
        return isHover ? Colr.controlSelect().opacity(0.3) : Color.black.opacity(0.0)
    }
    
    init(app: PlayApp) {
        _app = State(initialValue: app)
    }
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 0) {
            if let img = app.icon {
                Image(nsImage: img).resizable()
                    .frame(width: 88, height: 88).cornerRadius(10).shadow(radius: 1).padding(.top, 8)
                Text(app.name).frame(width: 150, height: 40).lineLimit(2).multilineTextAlignment(.center).padding(.bottom, 14)
            }
        }.background(colorScheme == .dark ? elementColor(true) : elementColor(false))
            .cornerRadius(16.0)
            .frame(width: 150, height: 150)
            .onTapGesture {
                isHover = false
                AnalyticsService.shared.logAppLaunch(app.id)
                app.launch()
            }
            .contextMenu {
                Button(action: {
                    showSettings.toggle()
                }) {
                    Text("App settings")
                    Image(systemName: "gear")
                }
                
                Button(action: {
                    app.showInFinder()
                }) {
                    Text("Show in Finder")
                    Image(systemName: "folder")
                }
                
                Button(action: {
                    app.openAppCache()
                }) {
                    Text("Open app cache")
                    Image(systemName: "folder")
                }
                
                Button(action: {
                    showClearCacheAlert.toggle()
                }) {
                    Text("Clear app cache")
                    Image(systemName: "xmark.bin")
                }
                
                Button(action: {
                    app.settings.importOf { result in
                        if result != nil {
                            showImportSuccess = true
                        } else{
                            showImportFail = true
                        }
                    }

                }) {
                    Text("Import keymapping")
                    Image(systemName: "square.and.arrow.down.on.square.fill")
                }
                
                Button(action: {
                    app.settings.export()
                }) {
                    Text("Export keymapping")
                    Image(systemName: "arrowshape.turn.up.left")
                }
                
                Button(action: {
                    app.deleteApp()
                }) {
                    Text("Delete app")
                    Image(systemName: "trash")
                }
            }
            .onHover(perform: { hovering in
                isHover = hovering
            }).sheet(isPresented: $showSettings) {
                AppSettingsView(settings: app.settings, adaptiveDisplay: app.settings.adaptiveDisplay, keymapping: app.settings.keymapping, gamingMode: app.settings.gamingMode, bypass: app.settings.bypass, selectedRefreshRate: app.settings.refreshRate == 60 ? 0 : 1, sensivity: app.settings.sensivity).frame(minWidth: 500)
            }.sheet(isPresented: $showSetup) {
                SetupView()
            }.alert("All app data will be erased. You may need to redownload app files again. Wish to continue?", isPresented: $showClearCacheAlert) {
                Button("OK", role: .cancel) {
                    app.container?.clear()
                    showClearCacheToast.toggle()
                }
                Button("Cancel", role: .cancel) {}
            }.toast(isPresenting: $showClearCacheToast){
                AlertToast(type: .regular, title: "App cache was cleared!")
            }.toast(isPresenting: $showImportSuccess){
                AlertToast(type: .regular, title: "Keymapping imported!")
            }.toast(isPresenting: $showImportFail){
                AlertToast(type: .regular, title: "Error during import!")
            }
    }
}
