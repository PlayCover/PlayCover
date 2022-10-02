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

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                ScrollView {
                    if !isList {
                        LazyVGrid(columns: gridLayout, alignment: .center) {
                            ForEach(storeVM.filteredApps, id: \.bundleID) { app in
                                StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                             selectedTextColor: $selectedTextColor,
                                             selected: $selected,
                                             app: app,
                                             isList: isList)
                                .environmentObject(DownloadVM.shared)
                            }
                        }
                        .padding()
                        Spacer()
                    } else {
                        VStack {
                            ForEach(storeVM.filteredApps, id: \.bundleID) { app in
                                StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
                                             selectedTextColor: $selectedTextColor,
                                             selected: $selected,
                                             app: app,
                                             isList: isList)
                                .environmentObject(DownloadVM.shared)
                            }
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            if storeVM.sources.count == 0 {
                VStack {
                    Spacer()
                    Text("No IPA Sources Added")
                        .font(.title)
                        .padding(.bottom, 2)
                    Text("You currently have no IPA Sources added. Click the button below to add one.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Button("Add Source", action: {
                        addSourcePresented.toggle()
                    })
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onTapGesture {
            selected = nil
        }
        .navigationTitle("sidebar.ipaLibrary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    addSourcePresented.toggle()
                }, label: {
                    Image(systemName: "plus")
                        .help("playapp.addSource")
                })
            }
            ToolbarItem(placement: .primaryAction) {
                Picker("", selection: $isList) {
                    Image(systemName: "square.grid.2x2")
                        .tag(false)
                    Image(systemName: "list.bullet")
                        .tag(true)
                }.pickerStyle(.segmented)
            }
        }
        .searchable(text: $searchString, placement: .toolbar)
        .onChange(of: searchString) { value in
            uif.searchText = value
            storeVM.fetchApps()
        }
        .onChange(of: isList, perform: { value in
            UserDefaults.standard.set(value, forKey: "IPALibrayView")
        })
        .sheet(isPresented: $addSourcePresented) {
            AddSourceView(addSourceSheet: $addSourcePresented)
                .environmentObject(storeVM)
        }
    }
}
