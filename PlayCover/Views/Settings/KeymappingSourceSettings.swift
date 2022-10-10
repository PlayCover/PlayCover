//
//  KeymappingSourceSettings.swift
//  PlayCover
//
//  Created by Nick on 2022-10-04.
//

import SwiftUI

struct KeymappingSourceSettings: View {
    @State var selected = Set<UUID>()
    @State var selectedNotEmpty = false
    @State var addSourceSheet = false
    @State var triggerUpdate = false
    @EnvironmentObject var storeVM: StoreVM

    var body: some View {
        Form {
            HStack {
                List(storeVM.keymappingSources, id: \.id, selection: $selected) { source in
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
                        storeVM.deleteKeymappingSource(&selected)
                    }, label: {
                        Text("preferences.button.deleteSource")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                    Spacer()
                        .frame(height: 20)
                    Button(action: {
                        storeVM.moveKeymappingSourceUp(&selected)
                    }, label: {
                        Text("preferences.button.moveSourceUp")
                            .frame(width: 130)
                    })
                    .disabled(!selectedNotEmpty)
                    Button(action: {
                        storeVM.moveKeymappingSourceDown(&selected)
                    }, label: {
                        Text("preferences.button.moveSourceDown")
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
            AddKeymappingSourceView(addSourceSheet: $addSourceSheet)
                .environmentObject(storeVM)
        }
    }

    func addSource() {
        addSourceSheet.toggle()
    }
}

struct AddKeymappingSourceView: View {
    @State var newSource = "https://api.github.com/repos/PlayCover/keymaps/contents/keymapping"
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
                    ProgressView()
                }
                Spacer()
                Button(action: {
                    addSourceSheet.toggle()
                }, label: {
                    Text("button.Cancel")
                })
                Button(action: {
                    if newSourceURL != nil {
                        storeVM.appendKeymappingSourceData(
                            SourceData(source: newSourceURL!.absoluteString)
                        )
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
            Task {
                await validateSource(source)
            }
        }
        .onAppear {
            Task {
                await validateSource(newSource)
            }
        }
    }

    func validateSource(_ source: String) async {
        struct KeymapFolder: Codable {
            var name: String
            var url: String
            var htmlUrl: String
        }

        struct KeymapInfo: Codable, Hashable {
            var name: String
            var downloadUrl: String
        }

        sourceValidationState = .checking

        do {
            var fetchedKeymapsFolder: KeymapFolder?
            var fetchedKeymaps = [KeymapInfo]()

            if let url = URL(string: source) {
                newSourceURL = url

                if StoreVM.checkAvaliability(url: newSourceURL!) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)

                        do {
                            let decoder = JSONDecoder()
                            decoder.keyDecodingStrategy = .convertFromSnakeCase

                            let decodedResponse = try decoder.decode([KeymapFolder].self, from: data)

                            for index in 0..<decodedResponse.count {
                                fetchedKeymapsFolder = decodedResponse[index]

                                let (data, _) = try await URLSession.shared.data(
                                    from: URL(string: fetchedKeymapsFolder!.url)!)
                                let decodedResponse = try decoder.decode([KeymapInfo].self, from: data)
                                fetchedKeymaps = decodedResponse.filter {
                                    $0.name.contains(".playmap")
                                }

                                if fetchedKeymaps.count > 0 {
                                    sourceValidationState = .valid
                                    return
                                }
                            }
                        } catch {
                            sourceValidationState = .badjson
                            print(error)
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

struct KeymappingSourceSettings_Previews: PreviewProvider {
    static var previews: some View {
        KeymappingSourceSettings()
    }
}
