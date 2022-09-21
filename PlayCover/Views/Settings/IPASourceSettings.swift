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
    var status: SourceValidation = .valid
}

struct IPASourceSettings: View {
    @State var selected = Set<UUID>()
    @State var selectedNotEmpty = false
    @State var addSourceSheet = false

    @State var sources: [SourceData] = [
        SourceData(source: "https://www.ipasrcool.net", status: .badjson),
        SourceData(source: "https://super.cool.app"),
        SourceData(source: "https://www.super-dooper-derypt.org"),
        SourceData(source: "https://www.ipasrcool.net"),
        SourceData(source: "https://super.cool.app"),
        SourceData(source: "https://www.super-dooper-derypt.org", status: .badurl),
        SourceData(source: "https://www.ipasrcool.net"),
        SourceData(source: "https://super.cool.app"),
        SourceData(source: "https://www.super-dooper-derypt.org")
    ]

    var body: some View {
        Form {
            HStack {
                List(sources, id: \.id, selection: $selected) { source in
                    SourceView(source: source)
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
                    Spacer()
                        .frame(height: 20)
                    Button(action: {}, label: {
                        Text("Resolve Sources")
                            .frame(width: 130)
                    })
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

struct SourceView: View {
    var source: SourceData
    @State var showingPopover = false

    var body: some View {
        HStack {
            Text(source.source)
            Spacer()
            switch source.status {
            case .valid:
                StatusBadgeView(imageName: "checkmark.circle.fill",
                                imageColor: .green,
                                popoverText: "Link valid",
                                showingPopover: $showingPopover)
            case .badurl:
                StatusBadgeView(imageName: "xmark.circle.fill",
                                imageColor: .red,
                                popoverText: "URL invalid",
                                showingPopover: $showingPopover)
            case .badjson:
                StatusBadgeView(imageName: "xmark.circle.fill",
                                imageColor: .red,
                                popoverText: "JSON not found or invalid",
                                showingPopover: $showingPopover)
            case .checking:
                EmptyView()
            }
        }
    }
}

struct StatusBadgeView: View {
    var imageName: String
    var imageColor: Color
    var popoverText: String
    @Binding var showingPopover: Bool

    var body: some View {
        Button(action: {
            showingPopover.toggle()
        }, label: {
            Image(systemName: imageName)
                .foregroundColor(imageColor)
        })
        .buttonStyle(.plain)
        .popover(isPresented: $showingPopover) {
            Text(popoverText)
                .padding(10)
        }
    }
}

enum SourceValidation {
    case valid, badurl, badjson, checking
}

struct AddSourceView: View {
    @State var newSource = ""
    @State var newSourceURL: URL?
    @State var sourceValidationState = SourceValidation.checking
    @Binding var sources: [SourceData]
    @Binding var addSourceSheet: Bool

    var body: some View {
        VStack {
            TextField(text: $newSource, label: {Text("Source URL...")})
            Spacer()
                .frame(height: 20)
            HStack {
                switch sourceValidationState {
                case .valid:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Link valid")
                        .font(.system(.subheadline))
                case .badurl:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("URL invalid")
                        .font(.system(.subheadline))
                case .badjson:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("JSON not found or invalid")
                        .font(.system(.subheadline))
                case .checking:
                    EmptyView()
                }
                Spacer()
                Button(action: {
                    addSourceSheet.toggle()
                }, label: {
                    Text("Cancel")
                })
                Button(action: {
                    if newSourceURL != nil {
                        sources.append(SourceData(source: newSourceURL!.absoluteString))
                        addSourceSheet.toggle()
                    }
                }, label: {
                    Text("Done")
                })
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
                .disabled(sourceValidationState != .valid)
            }
        }
        .padding()
        .frame(width: 400, height: 100)
        .onChange(of: newSource) { source in
            validateSource(source)
        }
    }

    func validateSource(_ source: String) {
        sourceValidationState = .checking
        DispatchQueue.global(qos: .userInteractive).async {
            if let url = URL(string: source) {
                newSourceURL = url
                if StoreVM.checkAvaliability(url: newSourceURL!) {
                    do {
                        if newSourceURL!.scheme == nil {
                            newSourceURL = URL(string: "https://" + newSourceURL!.absoluteString)!
                        }
                        let contents = try String(contentsOf: newSourceURL!)
                        let jsonData = contents.data(using: .utf8)!
                        do {
                            let data: [StoreAppData] = try JSONDecoder().decode([StoreAppData].self, from: jsonData)
                            if data.count > 0 {
                                sourceValidationState = .valid
                                return
                            }
                        } catch {
                            sourceValidationState = .badjson
                            return
                        }
                    } catch {
                        sourceValidationState = .badurl
                        return
                    }
                }
            }
            sourceValidationState = .badurl
            return
        }
    }
}

struct IPASourceSettings_Previews: PreviewProvider {
    static var previews: some View {
        IPASourceSettings()
    }
}
