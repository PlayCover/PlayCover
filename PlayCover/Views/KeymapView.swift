//
//  KeymapView.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 7/6/24.
//

import SwiftUI
import DataCache

enum KeymapNameValidation {
    case malformed, duplicate, empty, valid
}

struct KeymapView: View {

    let app: PlayApp

    @Binding var showKeymapSheet: Bool

    @State var selectedName: String?
    @State var kmName = ""

    @State var defaultKm = "default"

    @State var showKeymapImport = false
    @State var showKeymapRename = false

    @State var showImportSuccess = false
    @State var showImportFail = false
    @State var showRenameSuccess = false
    @State var showRenameFail = false
    @State var resetKmCompletedAlert = false
    @State var deleteKmCompletedMap = ""
    @State var deleteKmFailedMap = ""

    @State var appIcon: NSImage?
    @State private var cache = DataCache.instance

    var body: some View {
        VStack {
            HStack {
                Group {
                    if let image = appIcon {
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

                Text(String(format: NSLocalizedString("keymap.title", comment: ""), app.name))
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .task(priority: .userInitiated) {
                appIcon = cache.readImage(forKey: app.info.bundleIdentifier)
            }

            List(Array(app.keymapping.keymapURLs.keys).sorted(by: <), id: \.self, selection: $selectedName) { keymap in
                HStack {
                    Text(keymap)

                    Spacer()

                    if keymap == defaultKm {
                        Text("keymap.default")
                            .font(.footnote)
                            .padding(5)
                            .background(.regularMaterial.blendMode(.exclusion), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .contextMenu {
                    Group {
                        if keymap != defaultKm {
                            Button(action: {
                                app.keymapping.keymapConfig.defaultKm = keymap
                                defaultKm = keymap
                            }, label: {
                                Text("settings.defaultKm")
                            })
                            Divider()
                        }
                        Button(action: {
                            showKeymapRename.toggle()
                        }, label: {
                            Text("settings.renameKm")
                        })
                        Button(role: .destructive, action: {
                            if app.keymapping.deleteKeymap(name: kmName) {
                                deleteKmCompletedMap = kmName
                            } else {
                                deleteKmFailedMap = kmName
                            }
                            showKeymapSheet.toggle()
                        }, label: {
                            Text("settings.deleteKm")
                        })
                        Button(role: .destructive, action: {
                            app.keymapping.reset(name: kmName)
                            showKeymapSheet.toggle()
                            resetKmCompletedAlert.toggle()
                        }, label: {
                            Text("settings.resetKm")
                        })
                    }
                    .onAppear {
                        selectedName = keymap
                    }
                }
            }
            .listStyle(.bordered(alternatesRowBackgrounds: true))

            Spacer()
                .frame(height: 20)

            HStack {
                Spacer()
                .disabled(selectedName == nil)
                Button(action: {
                    showKeymapImport.toggle()
                }, label: {
                    Text("playapp.importKm")
                })
                Button(action: {
                    app.keymapping.exportKeymap(name: kmName)
                }, label: {
                    Text("playapp.exportKm")
                })
                .disabled(selectedName == nil)
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
            defaultKm = app.keymapping.keymapConfig.defaultKm
        }
        .onChange(of: selectedName) { _ in
            if let selectedName = selectedName {
                kmName = selectedName
            } else {
                kmName = ""
            }
        }
        .onChange(of: showImportSuccess) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("alert.kmImported", comment: ""))
        }
        .onChange(of: showImportFail) { _ in
            ToastVM.shared.showToast(
                toastType: .error,
                toastDetails: NSLocalizedString("alert.errorImportKm", comment: ""))
        }
        .onChange(of: showRenameSuccess) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("alert.kmRenamed", comment: ""))
        }
        .onChange(of: showRenameFail) { _ in
            ToastVM.shared.showToast(
                toastType: .error,
                toastDetails: NSLocalizedString("alert.errorRenameKm", comment: ""))
        }
        .onChange(of: resetKmCompletedAlert) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: NSLocalizedString("settings.resetKmCompleted", comment: ""))
        }
        .onChange(of: deleteKmCompletedMap) { _ in
            ToastVM.shared.showToast(
                toastType: .notice,
                toastDetails: String(format: NSLocalizedString("settings.deleteKmCompleted", comment: ""),
                                     deleteKmCompletedMap)
            )
        }
        .onChange(of: deleteKmFailedMap) { _ in
            ToastVM.shared.showToast(
                toastType: .error,
                toastDetails: String(format: NSLocalizedString("settings.deleteKmFailed", comment: ""),
                                     deleteKmFailedMap)
            )
        }
        .sheet(isPresented: $showKeymapImport) {
            KeymapNamerView(app: app,
                            title: NSLocalizedString("keymap.title.import", comment: ""),
                            callback: { name in
                                app.keymapping.importKeymap(name: name) { success in
                                    showKeymapSheet.toggle()
                                    if success {
                                        showImportSuccess.toggle()
                                    } else {
                                        showImportFail.toggle()
                                    }
                                }
                            },
                            keymapNamerSheet: $showKeymapImport)
        }
        .sheet(isPresented: $showKeymapRename) {
            KeymapNamerView(app: app,
                            title: NSLocalizedString("keymap.title.rename", comment: ""),
                            callback: { name in
                                showKeymapSheet.toggle()
                                if app.keymapping.renameKeymap(prevName: kmName, newName: name) {
                                    showRenameSuccess.toggle()
                                } else {
                                    showRenameFail.toggle()
                                }
                            },
                            keymapNamerSheet: $showKeymapRename)
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
                    keymapNamerSheet.toggle()

                    callback(name)
                }, label: {
                    Text("button.Proceed")
                })
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
                .disabled(![.valid].contains(nameValidationState))
            }
        }
        .padding()
        .frame(width: 400, height: 100)
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
