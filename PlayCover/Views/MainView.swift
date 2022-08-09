//
//  MainView.swift
//  PlayCover
//

import SwiftUI

struct MainView: View {
    @Environment(\.openURL) var openURL
    @EnvironmentObject var install: InstallVM
    @EnvironmentObject var apps: AppsVM
    @EnvironmentObject var store: StoreVM
    @EnvironmentObject var integrity: AppIntegrity

    @Binding public var xcodeCliInstalled: Bool

    @State private var selectedView: Int? = -1
    @State private var navWidth: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var sidebarVisible: Bool = true

    var body: some View {
        GeometryReader { viewGeom in
            NavigationView {
                GeometryReader { sidebarGeom in
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
                    .onChange(of: sidebarGeom.size) { newSize in
                        navWidth = newSize.width
                    }
                }
            }
            .navigationViewStyle(.columns)
            .onAppear {
                self.selectedView = 1
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: toggleSidebar, label: {
                        Image(systemName: "sidebar.leading")
                    })
                }
            }
            .overlay {
                HStack {
                    if sidebarVisible {
                        Spacer()
                            .frame(width: navWidth)
                    }
                    ToastView()
                        .environmentObject(ToastVM.shared)
                        .environmentObject(InstallVM.shared)
                        .frame(width: sidebarVisible ? (viewWidth - navWidth) : viewWidth)
                        .animation(.spring(), value: sidebarVisible)
                }
            }
            .onChange(of: viewGeom.size) { newSize in
                viewWidth = newSize.width
            }
        }
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        sidebarVisible.toggle()
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var xcodeCliInstalled = true

    static var previews: some View {
        MainView(xcodeCliInstalled: $xcodeCliInstalled)
            .environmentObject(InstallVM.shared)
            .environmentObject(AppsVM.shared)
            .environmentObject(StoreVM.shared)
            .environmentObject(AppIntegrity())
    }
}
