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

    var body: some View {
        VStack(alignment: .leading) {
            if !isList {
                ScrollView {
                    LazyVGrid(columns: gridLayout, alignment: .center) {
                        ForEach(storeVM.apps, id: \.id) { app in
                            StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
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
                        ForEach(storeVM.apps, id: \.id) { app in
                            StoreAppView(selectedBackgroundColor: $selectedBackgroundColor,
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
        .navigationTitle("sidebar.ipaLibrary")
        .toolbar {
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
        .onChange(of: searchString, perform: { value in
            uif.searchText = value
            storeVM.fetchApps()
        })
        .onChange(of: isList, perform: { value in
            UserDefaults.standard.set(value, forKey: "IPALibrayView")
        })
    }
}
