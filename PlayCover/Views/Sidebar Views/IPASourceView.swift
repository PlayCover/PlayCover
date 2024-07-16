//
//  IPASourceView.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 1/21/1402 AP.
//

import SwiftUI

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
            ToolbarItem(placement: .primaryAction) {
                StackNavigationSearchable(searchTitle: "textfield.searchApps",
                                          searchString: $searchString)
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