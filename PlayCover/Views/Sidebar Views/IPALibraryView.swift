//
//  IPALibrary.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct IPALibraryView: View {
    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150))]
    @State private var searchString = ""

    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geom in
                ScrollView  {
                    LazyVGrid(columns: gridLayout, alignment: .center) {
                        ForEach(Store.storeApps, id: \.id) { app in
                            StoreAppGridView(app: app)
                        }
                    }
                    .padding()
                    .animation(.spring(blendDuration: 0.1), value: geom.size.width)
                }
            }
        }
        .navigationTitle("IPA Library")
        .searchable(text: $searchString, placement: .toolbar)
        .onChange(of: searchString, perform: { value in
            uif.searchText = value
            AppsVM.shared.fetchApps()
        })
    }
}

struct IPALibraryView_Previews: PreviewProvider {
    static var previews: some View {
        IPALibraryView()
    }
}
