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

    @State private var selectedView: Int? = 0

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: AppLibraryView(), tag: 1, selection: self.$selectedView) {
                    Label("App Library", systemImage: "square.grid.2x2")
                }
            }
            .listStyle(.sidebar)
        }
        .onAppear {
            self.selectedView = 1
        }
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var xcodeCliInstalled = true

    static var previews: some View {
        MainView(xcodeCliInstalled: $xcodeCliInstalled)
            .environmentObject(InstallVM.shared)
            .environmentObject(AppsVM.shared)
            .environmentObject(AppIntegrity())
    }
}
