//
//  AppLibraryView.swift
//  PlayCover
//

import SwiftUI

struct AppLibraryView: View {
    @EnvironmentObject var appsVM: AppsVM
    @EnvironmentObject var installVM: InstallVM

    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150))]
    @State private var searchString = ""
    @State private var gridViewLayout = 0
    @State private var selected: PlayApp?
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geom in
                if gridViewLayout == 0 {
                    ScrollView {
                        LazyVGrid(columns: gridLayout, alignment: .leading) {
                            ForEach(appsVM.apps, id: \.info.bundleIdentifier) { app in
                                PlayAppView(app: app, isList: false, selected: $selected)
                            }
                        }
                        .padding()
                        .animation(.spring(blendDuration: 0.1), value: geom.size.width)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack {
                            ForEach(appsVM.apps, id: \.info.bundleIdentifier) { app in
                                PlayAppView(app: app, isList: true, selected: $selected)
                            }
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
        }
        .onTapGesture {
            selected = nil
        }
        .navigationTitle("sidebar.appLibrary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    showSettings.toggle()
                }, label: {
                    Image(systemName: "gear")
                })
                .disabled(selected == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Spacer()
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    if installVM.installing {
                        Log.shared.error(PlayCoverError.waitInstallation)
                    } else {
                        selectFile()
                    }
                }, label: {
                    Image(systemName: "plus")
                        .help("playapp.add")
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
        .onChange(of: searchString, perform: { value in
            uif.searchText = value
            appsVM.fetchApps()
        })
        .sheet(isPresented: $showSettings) {
            AppSettingsView(viewModel: AppSettingsVM(app: selected!))
        }
    }

    private func installApp() {
        Installer.install(ipaUrl: uif.ipaUrl!, returnCompletion: { _ in
            DispatchQueue.main.async {
                appsVM.fetchApps()
                NotifyService.shared.notify(
                    NSLocalizedString("notification.appInstalled", comment: ""),
                    NSLocalizedString("notification.appInstalled.message", comment: ""))
            }
        })
    }

    private func selectFile() {
        NSOpenPanel.selectIPA { result in
            if case .success(let url) = result {
                uif.ipaUrl = url
                installApp()
            }
        }
    }
}
