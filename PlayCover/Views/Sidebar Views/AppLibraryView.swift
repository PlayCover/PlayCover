//
//  AppLibraryView.swift
//  PlayCover
//

import SwiftUI

struct AppLibraryView: View {
    @EnvironmentObject var appsVM: AppsVM
    @EnvironmentObject var installVM: InstallVM

    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color

    @State private var gridLayout = [GridItem(.adaptive(minimum: 130, maximum: .infinity))]
    @State private var searchString = ""
    @State private var isList = UserDefaults.standard.bool(forKey: "AppLibrayView")
    @State private var selected: PlayApp?
    @State private var showSettings = false
    @State private var showLegacyConvertAlert = false
    @State private var showWrongfileTypeAlert = false

    var body: some View {
        VStack(alignment: .leading) {
            if !isList {
                ScrollView {
                    LazyVGrid(columns: gridLayout, alignment: .center) {
                        ForEach(appsVM.apps, id: \.info.bundleIdentifier) { app in
                            PlayAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                        selectedTextColor: $selectedTextColor,
                                        selected: $selected,
                                        app: app,
                                        isList: isList)
                        }
                    }
                    .padding()
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack {
                        ForEach(appsVM.apps, id: \.info.bundleIdentifier) { app in
                            PlayAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                        selectedTextColor: $selectedTextColor,
                                        selected: $selected,
                                        app: app,
                                        isList: isList)
                        }
                        Spacer()
                    }
                    .padding()
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
                Picker("Grid View Layout", selection: $isList) {
                    Image(systemName: "square.grid.2x2")
                        .tag(false)
                    Image(systemName: "list.bullet")
                        .tag(true)
                }.pickerStyle(.segmented)
            }
        }
        .searchable(text: $searchString, placement: .toolbar)
        .onChange(of: searchString, perform: { value in
            uif.searchText = value
            appsVM.fetchApps()
        })
        .onChange(of: isList, perform: { value in
            UserDefaults.standard.set(value, forKey: "AppLibrayView")
        })
        .sheet(isPresented: $showSettings) {
            AppSettingsView(viewModel: AppSettingsVM(app: selected!))
        }
        .onAppear {
            showLegacyConvertAlert = LegacySettings.doesMonolithExist
        }
        .onDrop(of: ["public.url", "public.file-url"], isTargeted: nil) { (items) -> Bool in
            if installVM.installing {
                Log.shared.error(PlayCoverError.waitInstallation)
                return false
            } else if let item = items.first {
                if let identifier = item.registeredTypeIdentifiers.first {
                    if identifier == "public.url" || identifier == "public.file-url" {
                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, _) in
                            DispatchQueue.main.async {
                                if let urlData = urlData as? Data {
                                    let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                    if url.pathExtension == "ipa" {
                                        uif.ipaUrl = url
                                        installApp()
                                    } else {
                                        showWrongfileTypeAlert = true
                                    }
                                }
                            }
                        }
                    }
                }
                return true
            } else {
                return false
            }
        }
        .alert(isPresented: $showWrongfileTypeAlert) {
            Alert(title: Text("alert.wrongFileType.title"),
                  message: Text("alert.wrongFileType.subtitle"), dismissButton: .default(Text("button.OK")))
        }
        .alert("Legacy App Settings Detected!", isPresented: $showLegacyConvertAlert, actions: {
            Button("button.Convert", role: .destructive) {
                LegacySettings.convertLegacyMonolithPlist(LegacySettings.monolithURL)
                do {
                    try FileManager.default.removeItem(at: LegacySettings.monolithURL)
                } catch {
                    Log.shared.error(error)
                }
            }
            .keyboardShortcut(.defaultAction)
            Button("button.Cancel", role: .cancel) {
                showLegacyConvertAlert.toggle()
            }
        }, message: {
            Text("alert.legacyImport.subtitle")
        })
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
