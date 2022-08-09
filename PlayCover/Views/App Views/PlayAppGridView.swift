//
//  PlayAppView.swift
//  PlayCover
//

import SwiftUI

struct PlayAppGridView: View {
    @State var app: PlayApp
    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State private var showClearCacheToast = false
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
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHover ? Color.secondary : Color.clear, lineWidth: 1)
        )
        .frame(width: 150, height: 150)
        .onTapGesture {
            isHover = false
            shell.removeTwitterSessionCookie()
            if app.settings.enableWindowAutoSize {
                app.settings.gameWindowSizeWidth = Float(NSScreen.main?.frame.width ?? 1920)
                app.settings.gameWindowSizeHeight = Float(NSScreen.main?.frame.height ?? 1080)
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
    }
}
