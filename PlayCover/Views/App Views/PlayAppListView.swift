//
//  PlayAppListView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct PlayAppListView: View {
    @State var app: PlayApp
    @State private var showSettings = false
    @State private var showClearCacheAlert = false
    @State var isHover: Bool = false
    @State var showImportSuccess: Bool = false
    @State var showImportFail: Bool = false

    var body: some View {
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
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke((isHover ? Color.secondary : Color.clear), lineWidth: 1)
        )
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
