//
//  IPASourceSettings.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 20/09/2022.
//

import SwiftUI

struct SourceData: Identifiable, Hashable {
    var id = UUID()
    var source: String
}

struct IPASourceSettings: View {
    @State var selected = Set<UUID>()
    @State var selectedNotEmpty = false
    @State var addSourceSheet = false

    @State var sources: [SourceData] = [
        SourceData(source: "https://www.ipasrcool.net"),
        SourceData(source: "https://super.cool.app"),
        SourceData(source: "https://www.super-dooper-derypt.org"),
        SourceData(source: "https://www.ipasrcool.net"),
        SourceData(source: "https://super.cool.app"),
        SourceData(source: "https://www.super-dooper-derypt.org"),
        SourceData(source: "https://www.ipasrcool.net"),
        SourceData(source: "https://super.cool.app"),
        SourceData(source: "https://www.super-dooper-derypt.org")
    ]

    var body: some View {
        Form {
            HStack {
                List(sources, id: \.id, selection: $selected) { name in
                    Text(name.source)
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                Spacer()
                    .frame(width: 20)
                VStack {
                    Button(action: {
                        addSource()
                    }, label: {
                        Text("Add Source")
                            .frame(width: 130)
                    })
                    Button(action: {
                        deleteSource()
                    }, label: {
                        Text("Delete Source")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                    Spacer()
                        .frame(height: 20)
                    Button(action: {
                        moveSourceUp()
                    }, label: {
                        Text("Move Source Up")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                    Button(action: {
                        moveSourceDown()
                    }, label: {
                        Text("Move Source Down")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                }
            }
        }
        .onChange(of: selected) { _ in
            if selected.count > 0 {
                selectedNotEmpty = true
            } else {
                selectedNotEmpty = false
            }
        }
        .padding(20)
        .frame(width: 600, height: 300, alignment: .center)
        .sheet(isPresented: $addSourceSheet) {
            AddSourceView(sources: $sources, addSourceSheet: $addSourceSheet)
        }
    }

    func addSource() {
        addSourceSheet.toggle()
    }

    func deleteSource() {
        sources.removeAll(where: { selected.contains($0.id) })
        selected.removeAll()
    }

    func moveSourceUp() {
        let selectedData = sources.filter({ selected.contains($0.id) })
        sources.removeAll(where: { selected.contains($0.id) })
        sources.insert(contentsOf: selectedData, at: 0)
    }

    func moveSourceDown() {
        let selectedData = sources.filter({ selected.contains($0.id) })
        sources.removeAll(where: { selected.contains($0.id) })
        sources.append(contentsOf: selectedData)
    }
}

struct AddSourceView: View {
    @State var newSource = ""
    @Binding var sources: [SourceData]
    @Binding var addSourceSheet: Bool

    var body: some View {
        VStack {
            TextField(text: $newSource, label: {Text("Source URL...")})
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Link Valid")
                    .font(.system(.subheadline))
                Spacer()
                Button(action: {
                    addSourceSheet.toggle()
                }, label: {
                    Text("Cancel")
                })
                Button(action: {
                    sources.append(SourceData(source: newSource))
                    addSourceSheet.toggle()
                }, label: {
                    Text("Done")
                })
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 400, height: 100)
    }
}

struct IPASourceSettings_Previews: PreviewProvider {
    static var previews: some View {
        IPASourceSettings()
    }
}
