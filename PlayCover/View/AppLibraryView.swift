//
//  AppLibraryView.swift
//  PlayCover
//

import SwiftUI

struct AppLibraryView: View {
    @EnvironmentObject var appVm: AppsVM

    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 0)]
    @State private var searchString = ""

    var body: some View {
        VStack(alignment: .leading) {
            GeometryReader { geom in
                ScrollView {
                    LazyVGrid(columns: gridLayout, alignment: .center, spacing: 10) {
                        // TODO: Remove use of force cast
                        // swiftlint:disable force_cast
                        ForEach(appVm.apps, id: \.id) { app in
                            if app.type == .app {
                                PlayAppView(app: app as! PlayApp)
                            }
                        }
                    }
                    .padding(.all, 5)
                    .animation(.spring(blendDuration: 0.1), value: geom.size.width)
                }
			}
        }
        .navigationTitle("App Library")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}, label: {
                    Image(systemName: "square.grid.2x2")
                })
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: {}, label: {
                    Image(systemName: "list.bullet")
                })
            }
        }
        .searchable(text: $searchString, placement: .toolbar)
    }
}
