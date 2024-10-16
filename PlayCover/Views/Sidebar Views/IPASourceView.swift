//
//  IPASourceView.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 1/21/1402 AP.
//

import SwiftUI

struct IPASourceView: View {

    @ObservedObject var storeVM: StoreVM
    @EnvironmentObject var downloadVM: DownloadVM

    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @State var sourceName: String
    @State var sourceApps: [SourceAppsData]

    @State private var isList = UserDefaults.standard.bool(forKey: "IPALibraryView")
    @State private var sortAlphabetical = UserDefaults.standard.bool(forKey: "IPASourceAlphabetically")
    @State private var selected: SourceAppsData?
    @State private var searchString = ""
    @State private var filteredApps: [SourceAppsData] = []

    @State private var addSourcePresented = false
    @State private var showAppInfo = false

    @State private var gridLayout = [GridItem(.adaptive(minimum: 130, maximum: .infinity))]

    var body: some View {
        let sortedApps = sourceApps.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        ScrollView {
            if !isList {
                LazyVGrid(columns: gridLayout, alignment: .center) {
                    ForEach(searchString == ""
                            ? sortAlphabetical ? sortedApps : sourceApps
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
                            ? sortAlphabetical ? sortedApps : sourceApps
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
        .navigationTitle(sourceName)
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
                .disabled(storeVM.sourcesList.isEmpty)
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
                filteredApps = sourceApps.filter {
                    $0.name.lowercased().contains(value.lowercased())
                }
            }
        }
    }
}
