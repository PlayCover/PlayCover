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

            List(
                Array(viewModel.app.keymapping.keymapURLs.keys).sorted(by: <),
                id: \.self,
                selection: $viewModel.selectedName
            ) { keymap in
                HStack {
                    Text(keymap)

                    Spacer()

                    if keymap == viewModel.defaultKm {
                        Text("keymap.default")
                            .font(.footnote)
                            .padding(5)
                            .background(.regularMaterial.blendMode(.exclusion), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .contextMenu {
                    Group {
                        if keymap != viewModel.defaultKm {
                            Button(action: {
                                viewModel.app.keymapping.keymapConfig.defaultKm = keymap
                                viewModel.defaultKm = keymap
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
                        Button(role: .destructive, action: {
                            if !viewModel.app.keymapping.deleteKeymap(name: viewModel.kmName) {
                                Log.shared.error("Failed to delete keymap: \(viewModel.kmName)")
                            }
                            showKeymapSheet.toggle()
                        }, label: {
                            Text("settings.deleteKm")
                        })
                        Button(role: .destructive, action: {
                            viewModel.app.keymapping.reset(name: viewModel.kmName)
                            showKeymapSheet.toggle()
                            viewModel.resetKmCompletedAlert.toggle()
                        }, label: {
                            Text("settings.resetKm")
                        })
                    }
                    .onAppear {
                        viewModel.selectedName = keymap
                    }
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
                .disabled(viewModel.selectedName == nil)
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
        .onAppear {
            viewModel.defaultKm = viewModel.app.keymapping.keymapConfig.defaultKm
        }
        .onChange(of: viewModel.selectedName) { _ in
            if let selectedName = viewModel.selectedName {
                viewModel.kmName = selectedName
            } else {
                viewModel.kmName = ""
            }
        }
        .onChange(of: viewModel.showImportSuccess) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("alert.kmImported", comment: ""))
        }
        .onChange(of: viewModel.showImportFail) { _ in
            ToastVM.shared.showToast(
                toastType: .error,
                toastDetails: NSLocalizedString("alert.errorImportKm", comment: ""))
        }
        .onChange(of: viewModel.showRenameSuccess) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("alert.kmRenamed", comment: ""))
        }
        .onChange(of: viewModel.showRenameFail) { _ in
            ToastVM.shared.showToast(
                toastType: .error,
                toastDetails: NSLocalizedString("alert.errorRenameKm", comment: ""))
        }
        .onChange(of: viewModel.showCreateKeymapSuccess) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("alert.kmCreated", comment: ""))
        }
        .onChange(of: viewModel.showCreateKeymapFail) { _ in
            ToastVM.shared.showToast(
                toastType: .error,
                toastDetails: NSLocalizedString("alert.errorKmCreated", comment: ""))
        }
        .onChange(of: viewModel.resetKmCompletedAlert) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("settings.resetKmCompleted", comment: ""))
        }
        .onChange(of: viewModel.deleteKmCompletedMap) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: String(format: NSLocalizedString("settings.deleteKmCompleted", comment: ""),
                                     viewModel.deleteKmCompletedMap)
            )
        }
        .onChange(of: viewModel.deleteKmFailedMap) { _ in
            ToastVM.shared.showToast(
                toastType: .error,
                toastDetails: String(format: NSLocalizedString("settings.deleteKmFailed", comment: ""),
                                     viewModel.deleteKmFailedMap)
            )
        }
        .sheet(isPresented: $viewModel.showKeymapImport) {
            KeymapNamerView(app: viewModel.app,
                            title: NSLocalizedString("keymap.title.import", comment: ""),
                            callback: { name in
                                viewModel.app.keymapping.importKeymap(name: name) { success in
                                    showKeymapSheet.toggle()
                                    if success {
                                        viewModel.showImportSuccess.toggle()
                                    } else {
                                        viewModel.showImportFail.toggle()
                                    }
                                }
                            },
                            keymapNamerSheet: $viewModel.showKeymapImport)
        }
        .sheet(isPresented: $viewModel.showKeymapRename) {
            KeymapNamerView(app: viewModel.app,
                            title: NSLocalizedString("keymap.title.rename", comment: ""),
                            callback: { name in
                                showKeymapSheet.toggle()
                                if viewModel.app.keymapping.renameKeymap(prevName: viewModel.kmName,
                                                                         newName: name) {
                                    viewModel.showRenameSuccess.toggle()
                                } else {
                                    viewModel.showRenameFail.toggle()
                                }
                            },
                            keymapNamerSheet: $viewModel.showKeymapRename)
        }
        .sheet(isPresented: $viewModel.showCreateKeymap) {
            KeymapNamerView(app: viewModel.app,
                            title: NSLocalizedString("keymap.title.empty", comment: ""),
                            callback: { name in
                                showKeymapSheet.toggle()
                                if viewModel.app.keymapping.createEmptyKeymap(
                                    name: name,
                                    bundleId: viewModel.app.info.bundleIdentifier
                                ) {
                                    viewModel.showCreateKeymapSuccess.toggle()
                                } else {
                                    viewModel.showCreateKeymapFail.toggle()
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
            } else if app.keymapping.keymapURLs.keys.contains(newName) {
                nameValidationState = .duplicate
            } else if newName.isEmpty {
                nameValidationState = .empty
            } else {
                nameValidationState = .valid
            }
        }
    }

}
