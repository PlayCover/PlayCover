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

    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color

    @State private var gridLayout = [GridItem(.adaptive(minimum: 130, maximum: .infinity))]
    @State private var addSourcePresented = false
    @State private var currentSubview = AnyView(EmptyView())
    @State private var showingSubview = false

    var body: some View {
        StackNavigationView(currentSubview: $currentSubview,
                            showingSubview: $showingSubview,
                            transition: .none) {
            Group {
                if NetworkVM.isConnectedToNetwork() {
                    if storeVM.sourcesList.isEmpty {
                        VStack {
                            Spacer()
                            Text("ipaLibrary.noSources.title")
                                .font(.title)
                                .padding(.bottom, 2)
                            Text("ipaLibrary.noSources.subtitle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Button("ipaLibrary.noSources.button", action: {
                                addSourcePresented.toggle()
                            })
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: gridLayout, alignment: .center) {
                                ForEach(storeVM.sourcesData, id: \.hashValue) { source in
                                    Button {
                                        currentSubview = AnyView(IPASourceView(
                                            selectedBackgroundColor: $selectedBackgroundColor,
                                            selectedTextColor: $selectedTextColor,
                                            sourceName: source.name,
                                            sourceApps: source.data)
                                        )
                                        showingSubview = true
                                    } label: {
                                        VStack {
                                            if let url = URL(string: source.logo) {
                                                CachedAsyncImage(url: url, urlCache: .iconCache) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fit)
                                                } placeholder: {
                                                    ProgressView()
                                                        .progressViewStyle(.circular)
                                                }
                                                .frame(width: 60, height: 60)
                                                .cornerRadius(15)
                                                .shadow(radius: 1)
                                            }
                                            Text(source.name)
                                                .lineLimit(1)
                                                .multilineTextAlignment(.center)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 2)
                                        }
                                        .frame(width: 130, height: 130)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            Spacer()
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
                            Task {
                                await storeVM.resolveSources()
                            }
                        }
                    }
                }
            }
            .navigationTitle("sidebar.ipaLibrary")
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    currentSubview = AnyView(EmptyView())
                    showingSubview = false
                    storeVM.sourcesData.removeAll()
                    Task {
                        await storeVM.resolveSources()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .help("playapp.refreshSources")
                }
                .disabled(storeVM.sourcesList.isEmpty)
            }
            ToolbarItem(placement: .primaryAction) {
                                    Spacer()
                                }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    addSourcePresented.toggle()
                } label: {
                    Image(systemName: "plus")
                        .help("playapp.addSource")
                }
            }
        }
        .sheet(isPresented: $addSourcePresented) {
            AddSourceView(addSourceSheet: $addSourcePresented)
                .environmentObject(storeVM)
        }
        .onChange(of: URLObserved.type) {_ in
            addSourcePresented = URLObserved.type == .source
        }
        .onAppear {
            addSourcePresented = URLObserved.type == .source
        }
    }
}

struct IPASourceView: View {

    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color
    @State var sourceName: String
    @State var sourceApps: [SourceAppsData]

    @State private var gridLayout = [GridItem(.adaptive(minimum: 130, maximum: .infinity))]
    @State private var isList = UserDefaults.standard.bool(forKey: "IPALibraryView")
    @State private var sortAlphabetical = UserDefaults.standard.bool(forKey: "IPASourceAlphabetically")
    @State private var selected: SourceAppsData?
    @State private var searchString = ""
    @State private var filteredApps: [SourceAppsData] = []

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
                    ForEach(searchString == ""
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
        .searchable(text: $searchString, placement: .toolbar)
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
        .toolbar {
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
        .onChange(of: isList) { value in
            UserDefaults.standard.set(value, forKey: "IPALibraryView")
        }
        .onChange(of: sortAlphabetical) { value in
            UserDefaults.standard.set(value, forKey: "IPASourceAlphabetically")
        }
    }
}
