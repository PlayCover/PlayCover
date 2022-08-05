//
//  AppLibraryView.swift
//  PlayCover
//

import SwiftUI

struct AppLibraryView: View {
    @EnvironmentObject var appsVM: AppsVM
    @EnvironmentObject var installVM: InstallVM

    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 0)]
    @State private var searchString = ""
    @State private var gridViewLayout = 0

    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geom in
                ScrollView {
                    if gridViewLayout == 0 {
                        LazyVGrid(columns: gridLayout, alignment: .center, spacing: 10) {
                            // TODO: Remove use of force cast
                            // swiftlint:disable force_cast
                            ForEach(appsVM.apps, id: \.id) { app in
                                if app.type == .app {
                                    PlayAppView(app: app as! PlayApp)
                                }
                            }
                        }
                        .padding(.all, 5)
                        .animation(.spring(blendDuration: 0.1), value: geom.size.width)
                    } else {
                        VStack {
                            ForEach(appsVM.apps, id: \.id) { app in
                                if app.type == .app {
                                    PlayAppListView(app: app as! PlayApp)
                                }
                            }
                        }
                        .padding(.all, 5)
                        .animation(.spring(blendDuration: 0.1), value: geom.size.width)
                    }
                }
			}
        }
        .navigationTitle("App Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    if installVM.installing {
                        Log.shared.error(PlayCoverError.waitInstallation)
                    } else {
                        selectFile()
                    }
                }, label: {
                    Image(systemName: "plus")
                })
            }
            ToolbarItem(placement: .primaryAction) {
                Picker("Grid View Layout", selection: $gridViewLayout) {
                    Image(systemName: "square.grid.2x2")
                        .tag(0)
                    Image(systemName: "list.bullet")
                        .tag(1)
                }.pickerStyle(.segmented)
            }
        }
        .searchable(text: $searchString, placement: .toolbar)
    }

    private func installApp() {
        Installer.install(ipaUrl: uif.ipaUrl!, returnCompletion: { (_) in
            DispatchQueue.main.async {
                appsVM.fetchApps()
                NotifyService.shared.notify(
                    NSLocalizedString("notifcation.appInstalled", comment: ""),
                    NSLocalizedString("notification.appInstalled.message", comment: "")
                )
            }
        })
    }

    private func selectFile() {
        NSOpenPanel.selectIPA { (result) in
            if case let .success(url) = result {
                uif.ipaUrl = url
                installApp()
            }
        }
    }
}
