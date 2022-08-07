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

    @State private var selectedView: Int? = -1

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: HomeView(), tag: 0, selection: self.$selectedView) {
                    Label("Home", systemImage: "house")
                }
                Divider()
                NavigationLink(destination: AppLibraryView(), tag: 1, selection: self.$selectedView) {
                    Label("App Library", systemImage: "square.grid.2x2")
                }
                NavigationLink(destination: IPALibraryView(), tag: 2, selection: self.$selectedView) {
                    Label("IPA Library", systemImage: "arrow.down.circle")
                }
            }
            .listStyle(.sidebar)
        }
        .navigationViewStyle(.columns)
        .onAppear {
            self.selectedView = 0
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.leading")
                })
            }
        }
        .frame(minWidth: 650, minHeight: 400)
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
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
