//
//  IPALibrary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct IPALibraryView: View {
    @EnvironmentObject var storeVM: StoreVM

    @State private var gridLayout = [GridItem(.adaptive(minimum: 100.5, maximum: .infinity))]
    @State private var searchString = ""
    @State private var isList = UserDefaults.standard.bool(forKey: "IPALibrayView")
    @State private var selected: StoreAppData?

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                GeometryReader { _ in
                    if !isList {
                        ScrollView {
                            LazyVGrid(columns: gridLayout, alignment: .leading) {
                                ForEach(storeVM.apps, id: \.id) { app in
                                    StoreAppView(app: app, isList: isList, selected: $selected)
                                }
                            }
                            .padding()
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack {
                                ForEach(storeVM.apps, id: \.id) { app in
                                    StoreAppView(app: app, isList: isList, selected: $selected)
                                }
                                Spacer()
                            }
                            .padding()
                        }
                        .padding(.leading, 20)
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
}

struct IPALibraryView_Previews: PreviewProvider {
    static var previews: some View {
        IPALibraryView()
            .environmentObject(StoreVM.shared)
    }
}
