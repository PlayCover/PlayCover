//
//  PlayAppContextMenuView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

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
