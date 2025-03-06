//
//  AppFolderView.swift
//  PlayCover
//

import SwiftUI
import DataCache

struct AppFolderView: View {
    @EnvironmentObject var appsVM: AppsVM
    @EnvironmentObject var installVM: InstallVM
    @EnvironmentObject var downloadVM: DownloadVM
    @EnvironmentObject var appFolderVM: AppFolderVM

    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @Binding var folder: Folder

    @State private var gridLayout = [GridItem(.adaptive(minimum: 130, maximum: .infinity))]
    @State private var searchString = ""
    @State private var isList = UserDefaults.standard.bool(forKey: "AppLibraryView")
    @State private var selected: PlayApp?
    @State private var showSettings = false
    @State private var showLegacyConvertAlert = false
    @State private var showWrongfileTypeAlert = false
    @State private var addSheetApps = false
    var dynamicHeight: CGFloat {
        let count = CGFloat(appsVM.apps.count) * 85
        return min(count, 600)
    }

    var body: some View {
        Group {
            if !appsVM.apps.isEmpty || appsVM.updatingApps {
                ScrollView {
                    AppDisplayView(apps: appsVM.filteredApps.filter {
                        folder.apps.contains($0.info.bundleIdentifier)
                    },
                                      selectedBackgroundColor: $selectedBackgroundColor,
                                      selectedTextColor: $selectedTextColor,
                                      selected: $selected,
                                      isList: $isList,
                                      gridLayout: gridLayout)
                }
                .onTapGesture {
                    selected = nil
                }
            } else {
                VStack {
                    Text("playapp.noSources.title")
                        .font(.title)
                        .padding(.bottom, 2)
                    Text("playapp.noSources.subtitle")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("playapp.importIPA") {
                        if installVM.inProgress {
                            Log.shared.error(PlayCoverError.waitInstallation)
                        } else if downloadVM.inProgress {
                            Log.shared.error(PlayCoverError.waitDownload)
                        } else {
                            selectFile()
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("sidebar.appLibrary")
        .navigationSubtitle(folder.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if installVM.inProgress {
                        Log.shared.error(PlayCoverError.waitInstallation)
                    } else if downloadVM.inProgress {
                        Log.shared.error(PlayCoverError.waitDownload)
                    } else {
                        selectFile()
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .help("playapp.add")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Spacer()
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gear")
                }
                .disabled(selected == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Picker("Grid View Layout", selection: $isList) {
                    Image(systemName: "square.grid.2x2")
                        .tag(false)
                    Image(systemName: "list.bullet")
                        .tag(true)
                }.pickerStyle(.segmented)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addSheetApps.toggle()
                } label: {
                    Image(systemName: "pencil")
                        .help("folder.button.edit")
                }
            }
        }
        .searchable(text: $searchString, placement: .toolbar)
        .onChange(of: searchString, perform: { value in
            appsVM.searchText = value
            appsVM.fetchApps()
        })
        .onAppear {
            appsVM.searchText = ""
            appsVM.fetchApps()
        }
        .onChange(of: isList, perform: { value in
            UserDefaults.standard.set(value, forKey: "AppLibraryView")
        })
        .sheet(isPresented: $showSettings) {
            if let selected = selected {
                AppSettingsView(viewModel: AppSettingsVM(app: selected))
            }
        }
        .sheet(isPresented: $addSheetApps) {
            VStack {
                HStack {
                    TextField(text: $folder.name,
                              label: {Text("folder.textfield.name")})
                        .frame(height: 40)
                    Picker(selection: $folder.icon, label: Text("Icon")) {
                        ForEach(appFolderVM.icons, id: \.self) { icon in
                            Image(systemName: icon)
                        }
                    }.fixedSize()
                }
                List(AppsVM.shared.apps, id: \.url) { app in
                    AddAppSheet(isAppEnabled: folder.apps.contains(app.info.bundleIdentifier),
                                app: app,
                                folder: $folder
                    )
                }
                Spacer()
                    .frame(height: 40)
                HStack {
                    Spacer()
                    Button(NSLocalizedString("button.OK", comment: ""), action: {
                        addSheetApps.toggle()
                    })
                    .disabled(folder.name.isEmpty)
                    .keyboardShortcut(.defaultAction)
                    Button(NSLocalizedString("button.Cancel", comment: ""), action: {
                        folder = appFolderVM.folderWrap
                        addSheetApps.toggle()
                    })
                    .keyboardShortcut(.cancelAction)
                }
            }
            .padding()
            .frame(width: 600, height: dynamicHeight)
            .onAppear {
                appFolderVM.folderWrap = folder
            }
        }
        .onAppear {
            showLegacyConvertAlert = LegacySettings.doesMonolithExist
        }
        .onDrop(of: ["public.url", "public.file-url"], isTargeted: nil) { (items) -> Bool in
            if installVM.inProgress {
                Log.shared.error(PlayCoverError.waitInstallation)
                return false
            } else if downloadVM.inProgress {
                Log.shared.error(PlayCoverError.waitDownload)
                return false
            } else if let item = items.first {
                if let identifier = item.registeredTypeIdentifiers.first {
                    if identifier == "public.url" || identifier == "public.file-url" {
                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, _) in
                            Task { @MainActor in
                                if let urlData = urlData as? Data {
                                    let url = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                    if url.pathExtension == "ipa" {
                                        installApp(url)
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

    private func installApp(_ url: URL) {
        Installer.install(ipaUrl: url, export: false, returnCompletion: { _ in
            Task { @MainActor in
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
                installApp(url)
            }
        }
    }
}

struct AddAppSheet: View {
    @State var isAppEnabled: Bool
    @State var app: PlayApp
    @Binding var folder: Folder
    var body: some View {
        HStack {
            if let image = DataCache.instance.readImage(forKey: app.info.bundleIdentifier) {
                Image(nsImage: image)
                    .resizable()
                    .cornerRadius(10)
                    .shadow(radius: 1)
                    .frame(width: 28, height: 28)
            }
            Toggle(app.info.displayName, isOn: $isAppEnabled)
                .onChange(of: isAppEnabled) { _ in
                    if isAppEnabled && !folder.apps.contains(app.info.bundleIdentifier) {
                        folder.apps.append(app.info.bundleIdentifier)
                    } else {
                        folder.apps = folder.apps.filter { $0 != app.info.bundleIdentifier }
                    }
            }
        }
    }
}
