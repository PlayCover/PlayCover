//
//  IPALibrary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct IPALibraryView: View {
    @EnvironmentObject var storeVM: StoreVM

    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150))]
    @State private var searchString = ""
    @State private var gridViewLayout = 0
    @State private var selected: StoreAppData?

    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geom in
                if gridViewLayout == 0 {
                    ScrollView {
                        LazyVGrid(columns: gridLayout, alignment: .leading) {
                            ForEach(storeVM.apps, id: \.id) { app in
                                StoreAppView(app: app, isList: false, selected: $selected)
                            }
                        }
                        .padding()
                        .animation(.spring(blendDuration: 0.1), value: geom.size.width)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        VStack {
                            ForEach(storeVM.apps, id: \.id) { app in
                                StoreAppView(app: app, isList: true, selected: $selected)
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
        .navigationTitle("sidebar.ipaLibrary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Picker("", selection: $gridViewLayout) {
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
            storeVM.fetchApps()
        })
    }
}

struct IPALibraryView_Previews: PreviewProvider {
    static var previews: some View {
        IPALibraryView()
            .environmentObject(StoreVM.shared)
    }
}
