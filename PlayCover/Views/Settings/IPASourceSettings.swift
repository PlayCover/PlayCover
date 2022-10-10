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

    enum SourceDataKeys: String, CodingKey {
        case source
    }
}

extension SourceData: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SourceDataKeys.self)
        try container.encode(source, forKey: .source)
    }
}

extension SourceData: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: SourceDataKeys.self)
        source = try values.decode(String.self, forKey: .source)
    }
}

struct IPASourceSettings: View {
    @State var selected = Set<UUID>()
    @State var selectedNotEmpty = false
    @State var addSourceSheet = false
    @State var triggerUpdate = false
    @EnvironmentObject var storeVM: StoreVM

    var body: some View {
        Form {
            HStack {
                List(storeVM.sources, id: \.id, selection: $selected) { source in
                    SourceView(source: source)
                }
                .listStyle(.bordered(alternatesRowBackgrounds: true))
                Spacer()
                    .frame(width: 20)
                VStack {
                    Button(action: {
                        addSource()
                    }, label: {
                        Text("preferences.button.addSource")
                            .frame(width: 130)
                    })
                    Button(action: {
                        storeVM.deleteSource(&selected)
                    }, label: {
                        Text("preferences.button.deleteSource")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                    Spacer()
                        .frame(height: 20)
                    Button(action: {
                        storeVM.moveSourceUp(&selected)
                    }, label: {
                        Text("preferences.button.moveSourceUp")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                    Button(action: {
                        storeVM.moveSourceDown(&selected)
                    }, label: {
                        Text("preferences.button.moveSourceDown")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                    Spacer()
                        .frame(height: 20)
                    Button(action: {
                        storeVM.resolveSources()
                    }, label: {
                        Text("preferences.button.resolveSources")
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
            AddSourceView(addSourceSheet: $addSourceSheet)
                .environmentObject(storeVM)
        }
    }

    func addSource() {
        addSourceSheet.toggle()
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
                                popoverText: "preferences.popover.valid",
                                showingPopover: $showingPopover)
            case .badurl:
                StatusBadgeView(imageName: "xmark.circle.fill",
                                imageColor: .red,
                                popoverText: "preferences.popover.badurl",
                                showingPopover: $showingPopover)
            case .badjson:
                StatusBadgeView(imageName: "xmark.circle.fill",
                                imageColor: .red,
                                popoverText: "preferences.popover.badjson",
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
            Text(NSLocalizedString(popoverText, comment: ""))
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
    @Binding var addSourceSheet: Bool
    @EnvironmentObject var storeVM: StoreVM

    var body: some View {
        VStack {
            TextField(text: $newSource, label: {Text("preferences.textfield.url")})
            Spacer()
                .frame(height: 20)
            HStack {
                switch sourceValidationState {
                case .valid:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("preferences.popover.valid")
                        .font(.system(.subheadline))
                case .badurl:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("preferences.popover.badurl")
                        .font(.system(.subheadline))
                case .badjson:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("preferences.popover.badjson")
                        .font(.system(.subheadline))
                case .checking:
                    EmptyView()
                }
                Spacer()
                Button(action: {
                    addSourceSheet.toggle()
                }, label: {
                    Text("button.Cancel")
                })
                Button(action: {
                    if newSourceURL != nil {
                        storeVM.appendSourceData(SourceData(source: newSourceURL!.absoluteString))
                        addSourceSheet.toggle()
                    }
                }, label: {
                    Text("button.OK")
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
