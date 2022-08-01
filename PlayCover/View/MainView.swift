//
//  MainView.swift
//  PlayCover
//

import SwiftUI

struct MainView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var install: InstallVM
    @EnvironmentObject var apps: AppsVM
    @EnvironmentObject var integrity: AppIntegrity

    @Binding public var xcodeCliInstalled: Bool

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: {
                    AppLibraryView()
                }, label: {
                    Label("App Library", systemImage: "square.grid.2x2")
                })
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var xcodeCliInstalled = true

    static var previews: some View {
        MainView(xcodeCliInstalled: $xcodeCliInstalled)
    }
}
