//
//  IPALibrary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI
import CachedAsyncImage

struct IPALibraryView: View {

    @ObservedObject var storeVM: StoreVM
    @ObservedObject private var URLObserved = URLObservable.shared
    @EnvironmentObject var downloadVM: DownloadVM

    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color

    @State private var selected: SourceAppsData?

    @State private var searchString = ""
    @State private var filteredApps: [SourceAppsData] = []

    @State private var isList = UserDefaults.standard.bool(forKey: "IPALibraryView")
    @State private var sortAlphabetical = UserDefaults.standard.bool(forKey: "IPASourceAlphabetically")

    @State private var addSourcePresented = false
    @State private var showAppInfo = false

    @State private var gridLayout = [GridItem(.adaptive(minimum: 130, maximum: .infinity))]

    var body: some View {
        let enabledSources: [SourceJSON] = StoreVM.shared.sourcesData.filter { sourceJSON in
            return StoreVM.shared.sourcesList.contains { sourceData in
                sourceData.source == sourceJSON.sourceURL && sourceData.isEnabled
            }
        }
        let sortedApps = storeVM.sourcesApps.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        Group {
            if NetworkVM.isConnectedToNetwork() {
                if enabledSources.isEmpty {
                    VStack {
                        Spacer()
                        Text("ipaLibrary.noSources.title")
                            .font(.title)
                            .padding(.bottom, 2)
                        Text("ipaLibrary.noSources.subtitle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Button("ipaLibrary.noSources.button") {
                            addSourcePresented.toggle()
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if !isList {
                            LazyVGrid(columns: gridLayout, alignment: .center) {
                                ForEach(searchString.isEmpty
                                        ? sortAlphabetical ? sortedApps : storeVM.sourcesApps
                                        : filteredApps, id: \.bundleID) { app in
                                    StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                                 selectedTextColor: $selectedTextColor,
                                                 selected: $selected,
                                                 app: app,
                                                 isList: isList)
                                }
                            }
                            .padding()
                            Spacer()
                        } else {
                            VStack {
                                ForEach(searchString.isEmpty
                                        ? sortAlphabetical ? sortedApps : storeVM.sourcesApps
                                        : filteredApps, id: \.bundleID) { app in
                                    StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                                 selectedTextColor: $selectedTextColor,
                                                 selected: $selected,
                                                 app: app,
                                                 isList: isList)
                                    .environmentObject(DownloadVM.shared)
                                    .environmentObject(InstallVM.shared)
                                }
                                Spacer()
                            }
                            .padding()
                        }
                    }
                }
            } else {
                VStack {
                    Text("ipaLibrary.noNetworkConnection.toast")
                        .font(.title)
                        .padding(.bottom, 2)
                    Text("ipaLibrary.noNetworkConnection.required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("button.Reload") {
                        storeVM.resolveSources()
                    }
                }
            }
        }
        .navigationTitle("sidebar.ipaLibrary")
        .onTapGesture {
            selected = nil
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addSourcePresented.toggle()
                } label: {
                    Image(systemName: "plus.circle")
                        .help("playapp.addSource")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    storeVM.resolveSources()
                } label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .help("playapp.refreshSources")
                }
                .disabled(enabledSources.isEmpty)
            }
            ToolbarItem(placement: .primaryAction) {
                Spacer()
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAppInfo.toggle()
                } label: {
                    Image(systemName: "info.circle")
                }
                .disabled(selected == nil)
            }
            ToolbarItem(placement: .primaryAction) {
                Spacer()
            }
            ToolbarItem(placement: .primaryAction) {
                Toggle("A", isOn: $sortAlphabetical)
                    .help("ipaLibrary.AlphabeticalSort")
            }
            ToolbarItem(placement: .primaryAction) {
                Picker("", selection: $isList) {
                    Image(systemName: "square.grid.2x2")
                        .tag(false)
                    Image(systemName: "list.bullet")
                        .tag(true)
                }
                .pickerStyle(.segmented)
            }
        }
        .searchable(text: $searchString, placement: .toolbar)
        .sheet(isPresented: $addSourcePresented) {
            AddSourceView(addSourceSheet: $addSourcePresented)
                .environmentObject(storeVM)
        }
        .sheet(isPresented: $showAppInfo) {
            if let selected = selected {
                StoreInfoAppView(viewModel: StoreAppVM(data: selected))
                    .environmentObject(downloadVM)
            }
        }
        .onChange(of: isList) { value in
            UserDefaults.standard.set(value, forKey: "IPALibraryView")
        }
        .onChange(of: sortAlphabetical) { value in
            UserDefaults.standard.set(value, forKey: "IPASourceAlphabetically")
        }
        .onChange(of: searchString) { value in
            if sortAlphabetical {
                filteredApps = sortedApps.filter {
                    $0.name.lowercased().contains(value.lowercased())
                }
            } else {
                filteredApps = storeVM.sourcesApps.filter {
                    $0.name.lowercased().contains(value.lowercased())
                }
            }
        }
        .onChange(of: URLObserved.type) {_ in
            addSourcePresented = URLObserved.type == .source
        }
        .onAppear {
            addSourcePresented = URLObserved.type == .source
        }
    }
}
