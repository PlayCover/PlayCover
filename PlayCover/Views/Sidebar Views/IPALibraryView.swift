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
    @State private var searchString = ""
    @State private var filteredSources: [SourceJSON] = []

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
                                ForEach(searchString == ""
                                        ? storeVM.sourcesData
                                        : filteredSources, id: \.hashValue) { source in
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
                                                    Rectangle()
                                                         .fill(.regularMaterial)
                                                         .overlay {
                                                             ProgressView()
                                                                 .progressViewStyle(.circular)
                                                         }
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
                            storeVM.resolveSources()
                        }
                    }
                }
            }
            .navigationTitle("sidebar.ipaLibrary")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        storeVM.resolveSources()
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
                ToolbarItem(placement: .primaryAction) {
                    StackNavigationSearchable(searchTitle: "textfield.searchSources",
                                              searchString: $searchString)
                }
            }
        }
        .sheet(isPresented: $addSourcePresented) {
            AddSourceView(addSourceSheet: $addSourcePresented)
                .environmentObject(storeVM)
        }
        .onChange(of: searchString) { value in
            filteredSources = storeVM.sourcesData.filter {
                $0.name.lowercased().contains(value.lowercased())
            }
        }
        .onChange(of: URLObserved.type) {_ in
            addSourcePresented = URLObserved.type == .source
        }
        .onAppear {
            addSourcePresented = URLObserved.type == .source
        }
    }
}
