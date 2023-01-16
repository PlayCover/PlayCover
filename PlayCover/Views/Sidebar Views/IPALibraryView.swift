//
//  IPALibrary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct IPALibraryView: View {
    @EnvironmentObject var storeVM: StoreVM

    @Binding var selectedBackgroundColor: Color
    @Binding var selectedTextColor: Color

    @State private var gridLayout = [GridItem(.adaptive(minimum: 130, maximum: .infinity))]
    @State private var searchString = ""
    @State private var isList = UserDefaults.standard.bool(forKey: "IPALibrayView")
    @State private var selected: StoreAppData?
    @State private var addSourcePresented = false

    @State private var currentSubview = AnyView(EmptyView())
    @State private var showingSubview = false

    var body: some View {
        StackNavigationView(currentSubview: $currentSubview,
                            showingSubview: $showingSubview) {
            Group {
                if storeVM.sources.count == 0 {
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
                } else {
                    ScrollView {
                        if !isList {
                            LazyVGrid(columns: gridLayout, alignment: .center) {
                                ForEach(storeVM.filteredApps, id: \.bundleID) { app in
                                    Button {
                                        showSubview(view: AnyView(DetailStoreAppView(app: app,
                                                                                     downloadVM: DownloadVM.shared,
                                                                                     installVM: InstallVM.shared)))
                                    } label: {
                                        StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                                     selectedTextColor: $selectedTextColor,
                                                     selected: $selected,
                                                     app: app,
                                                     isList: isList)
                                        .environmentObject(DownloadVM.shared)
                                        .environmentObject(InstallVM.shared)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            Spacer()
                        } else {
                            VStack {
                                ForEach(storeVM.filteredApps, id: \.bundleID) { app in
                                    Button {
                                        showSubview(view: AnyView(DetailStoreAppView(app: app,
                                                                                     downloadVM: DownloadVM.shared,
                                                                                     installVM: InstallVM.shared)))
                                    } label: {
                                        StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                                     selectedTextColor: $selectedTextColor,
                                                     selected: $selected,
                                                     app: app,
                                                     isList: isList)
                                        .environmentObject(DownloadVM.shared)
                                        .environmentObject(InstallVM.shared)
                                    }
                                    .buttonStyle(.plain)
                                    Spacer()
                                }
                            }
                            .padding()
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                storeVM.resolveSources()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                                    .help("playapp.refreshSources")
                            }
                            .disabled(storeVM.sources.count == 0)
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
                    .onChange(of: searchString) { value in
                        uif.searchText = value
                        storeVM.fetchApps()
                    }
                }
            }
            .navigationTitle("sidebar.ipaLibrary")
            .onChange(of: isList, perform: { value in
                UserDefaults.standard.set(value, forKey: "IPALibrayView")
            })
            .sheet(isPresented: $addSourcePresented) {
                AddSourceView(addSourceSheet: $addSourcePresented)
                    .environmentObject(storeVM)
            }
        }
    }
    private func showSubview(view: AnyView) {
        currentSubview = view
        showingSubview = true
    }
}
