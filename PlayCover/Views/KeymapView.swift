//
//  KeymapView.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 7/6/24.
//

import SwiftUI

enum KeymapNameValidation {
    case malformed, duplicate, empty, valid
}

struct KeymapView: View {

    @Binding var showKeymapSheet: Bool

    @StateObject var viewModel: KeymapViewVM

    var body: some View {
        VStack {
            HStack {
                Group {
                    if let image = viewModel.appIcon {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .frame(width: 60, height: 60)
                    }
                }
                .cornerRadius(10)
                .shadow(radius: 1)
                .frame(width: 33, height: 33)

                Text(String(format: NSLocalizedString("keymap.title", comment: ""), viewModel.app.name))
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .task(priority: .userInitiated) {
                viewModel.appIcon = viewModel.cache.readImage(forKey: viewModel.app.info.bundleIdentifier)
            }

            List(selection: $viewModel.selectedKeymap) {
                ForEach(
                    viewModel.keymapURLS,
                    id: \.self
                ) { keymap in
                    HStack {
                        Text(keymap.deletingPathExtension().lastPathComponent)

                        Spacer()

                        if keymap == viewModel.defaultKm {
                            Text("keymap.default")
                                .font(.footnote)
                                .padding(5)
                                .background(Color.secondary.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                    .contextMenu {
                        Group {
                            if keymap != viewModel.defaultKm {
                                Button(action: {
                                    viewModel.setDefaultKeymap(keymap: keymap)
                                }, label: {
                                    Text("settings.defaultKm")
                                })
                                Divider()
                            }
                            Button(action: {
                                viewModel.showKeymapRename.toggle()
                            }, label: {
                                Text("settings.renameKm")
                            })
                            if keymap != viewModel.defaultKm {
                                Button(role: .destructive, action: {
                                    if !viewModel.app.keymapping.deleteKeymap(name: viewModel.kmName) {
                                        Log.shared.error(localized: "settings.deleteKmFailed", args: [viewModel.kmName])
                                    }

                                    viewModel.reloadKeymapCache()
                                }, label: {
                                    Text("settings.deleteKm")
                                })
                            }
                            Button(role: .destructive, action: {
                                viewModel.app.keymapping.reset(name: viewModel.kmName)
                            }, label: {
                                Text("settings.resetKm")
                            })
                        }
                        .onAppear {
                            viewModel.selectedKeymap = keymap
                        }
                    }
                }
                .onMove { src, dst in
                    viewModel.keymapURLS.move(fromOffsets: src, toOffset: dst)
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))

            Spacer()
                .frame(height: 20)

            HStack {
                Button(action: {
                    viewModel.showCreateKeymap.toggle()
                }, label: {
                    Text("playapp.emptyKm")
                })
                Spacer()
                Button(action: {
                    viewModel.showKeymapImport.toggle()
                }, label: {
                    Text("playapp.importKm")
                })
                Button(action: {
                    viewModel.app.keymapping.exportKeymap(name: viewModel.kmName)
                }, label: {
                    Text("playapp.exportKm")
                })
                .disabled(viewModel.selectedKeymap == nil)
                Button(action: {
                    showKeymapSheet.toggle()
                }, label: {
                    Text("button.Close")
                })
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 500, height: 350)
        .onChange(of: viewModel.selectedKeymap) { _ in
            if let selectedKeymap = viewModel.selectedKeymap {
                viewModel.kmName = selectedKeymap.deletingPathExtension().lastPathComponent
            } else {
                viewModel.kmName = ""
            }
        }
        .sheet(isPresented: $viewModel.showKeymapImport) {
            KeymapNamerView(app: viewModel.app,
                            title: NSLocalizedString("keymap.title.import", comment: ""),
                            callback: { name in
                                viewModel.app.keymapping.importKeymap(name: name) { success in
                                    viewModel.reloadKeymapCache()

                                    if !success {
                                        Log.shared.error(localized: "alert.errorImportKm")
                                    }
                                }
                            },
                            keymapNamerSheet: $viewModel.showKeymapImport)
        }
        .sheet(isPresented: $viewModel.showKeymapRename) {
            KeymapNamerView(app: viewModel.app,
                            title: NSLocalizedString("keymap.title.rename", comment: ""),
                            callback: { name in
                                if viewModel.app.keymapping.renameKeymap(prevName: viewModel.kmName,
                                                                         newName: name) {
                                    viewModel.reloadKeymapCache()
                                } else {
                                    Log.shared.error(localized: "alert.errorRenameKm")
                                }
                            },
                            keymapNamerSheet: $viewModel.showKeymapRename)
        }
        .sheet(isPresented: $viewModel.showCreateKeymap) {
            KeymapNamerView(app: viewModel.app,
                            title: NSLocalizedString("keymap.title.empty", comment: ""),
                            callback: { name in
                                if viewModel.app.keymapping.createEmptyKeymap(name: name) {
                                    viewModel.reloadKeymapCache()
                                } else {
                                    Log.shared.error(localized: "alert.errorKmCreated")
                                }
                            },
                            keymapNamerSheet: $viewModel.showCreateKeymap)
        }
    }

}

struct KeymapNamerView: View {

    let app: PlayApp
    let title: String
    let callback: (String) -> Void

    @State var name = ""
    @State var nameValidationState: KeymapNameValidation = .empty

    @Binding var keymapNamerSheet: Bool

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Text(title)
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)

                Spacer()
            }

            TextField(text: $name) {
                Text("keymap.sheet.name")
            }

            Spacer()
                .frame(height: 20)

            HStack {
                switch nameValidationState {
                case .malformed:
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                    Text("preferences.popover.malformed.keymap")
                        .font(.system(.subheadline))
                case .duplicate:
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                    Text("preferences.popover.duplicate.keymap")
                        .font(.system(.subheadline))
                case .empty:
                    EmptyView()
                case .valid:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("preferences.popover.valid.keymap")
                        .font(.system(.subheadline))
                }

                Spacer()

                Button(action: {
                    keymapNamerSheet.toggle()
                }, label: {
                    Text("button.Cancel")
                })

                Button(action: {
                    callback(name)

                    keymapNamerSheet.toggle()
                }, label: {
                    Text("button.Proceed")
                })
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
                .disabled(![.valid].contains(nameValidationState))
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 100)
        .padding()
        .onChange(of: name) { newName in
            if newName.esc != newName {
                nameValidationState = .malformed
            } else if app.keymapping.hasKeymap(name: newName) {
                nameValidationState = .duplicate
            } else if newName.isEmpty {
                nameValidationState = .empty
            } else {
                nameValidationState = .valid
            }
        }
    }

}
