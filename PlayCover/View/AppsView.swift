//
//  AppsLibraryView.swift
//  PlayCover
//

import Foundation

import SwiftUI
import Cocoa
import AppKit

struct AppsView: View {
    @Binding public var bottomPadding: CGFloat
    @Binding public var xcodeCliInstalled: Bool

    @EnvironmentObject var appVm: AppsVM

    @State private var gridLayout = [GridItem(.adaptive(minimum: 160, maximum: 160), spacing: 0)]
	@State private var alertTitle = ""
	@State private var alertText = ""
	@State private var alertBtn = ""
	@State private var alertAction : (() -> Void) = {}
	@State private var showAlert = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            HStack {
                SearchView().padding(.horizontal, 20).padding(.vertical, 8)
            }
			if !xcodeCliInstalled {
				VStack(spacing: 12) {
					Text("xcode.install.message")
						.font(.title3)
					Button("button.Install") {
						do {
							_ = try shell.sh("xcode-select --install")
							alertTitle = NSLocalizedString("xcode.install.success", comment: "")
							alertBtn = NSLocalizedString("button.Close", comment: "")
							alertText = NSLocalizedString("alert.followInstructionsAndRestartApp", comment: "")
							alertAction = {
								exit(0)
							}
							showAlert = true
						} catch {
							alertTitle = NSLocalizedString("xcode.install.failed", comment: "")
							alertBtn = NSLocalizedString("button.OK", comment: "")
							alertText = error.localizedDescription
							alertAction = {}
							showAlert = true
						}
					}
                    .buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
					.alert(isPresented: $showAlert) {
						Alert(title: Text(alertTitle), message: Text(alertText), dismissButton: .default(Text(alertBtn), action: {
							showAlert = false
							alertAction()
						}))
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.padding(.top, 16).padding(.bottom, bottomPadding + 16)
			} else {
                GeometryReader { geom in
                    ScrollView {
                        LazyVGrid(columns: gridLayout, alignment: .leading, spacing: 10) {
                            // swiftlint:disable todo
                            // TODO: Remove use of force cast
                            // swiftlint:disable force_cast
                            ForEach(appVm.apps, id: \.id) { app in
                                if app.type == BaseApp.AppType.add {
                                    AppAddView().environmentObject(InstallVM.shared)
                                } else if app.type == .app {
                                    PlayAppView(app: app as! PlayApp)
                                } else if app.type == .store {
                                    StoreAppView(app: app as! StoreApp)
                                }
                            }
                        }
                        .padding([.top, .leading], 16).padding(.bottom, bottomPadding + 16)
                        .animation(.spring(blendDuration: 0.1), value: geom.size.width)
                    }
                }
			}
        }
    }
}

struct AppAddView: View {

    @State var isHover: Bool = false
    @State var showWrongfileTypeAlert: Bool = false
    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject var install: InstallVM

    func elementColor(_ dark: Bool) -> Color {
        return isHover ? Color.gray.opacity(0.3) : Color.black.opacity(0.0)
    }

    var body: some View {

        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "plus.square")
                .font(.system(size: 38.0, weight: .thin))
                .frame(width: 64, height: 68).padding(.top).foregroundColor(
                    install.installing ? Color.gray : Color.accentColor)
            Text("playapp.add").padding(.horizontal)
                            .frame(width: 150, height: 50)
                            .padding(.bottom)
                            .lineLimit(nil)
                            .foregroundColor( install.installing ? Color.gray : Color.accentColor)
                            .minimumScaleFactor(0.8).multilineTextAlignment(.center)
        }.background(colorScheme == .dark ? elementColor(true) : elementColor(false))
            .cornerRadius(16.0)
            .frame(width: 150, height: 150).onHover(perform: { hovering in
                isHover = hovering
            }).alert(isPresented: $showWrongfileTypeAlert) {
                Alert(title: Text("alert.wrongFileType"),
                      message: Text("alert.wrongFileType.message"), dismissButton: .default(Text("button.OK")))
            }
            .onTapGesture {
                if install.installing {
                    isHover = false
                    Log.shared.error(PlayCoverError.waitInstallation)
                } else {
                    isHover = false
                    selectFile()
                }

            }.onDrop(of: ["public.url", "public.file-url"], isTargeted: nil) { (items) -> Bool in
                if install.installing {
                    Log.shared.error(PlayCoverError.waitInstallation)
                    return false
                } else if let item = items.first {
                    if let identifier = item.registeredTypeIdentifiers.first {
                        if identifier == "public.url" || identifier == "public.file-url" {
                            item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, _) in
                                DispatchQueue.main.async {
                                    if let urlData = urlData as? Data {
                                        let urll = NSURL(absoluteURLWithDataRepresentation:
                                                            urlData, relativeTo: nil) as URL
                                        if urll.pathExtension == "ipa"{
                                            uif.ipaUrl = urll
                                            installApp()
                                        } else {
                                            showWrongfileTypeAlert = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                    return true
                } else {
                    return false
                }
            }
            .onOpenURL {url in
                if url.pathExtension == "ipa"{
                    uif.ipaUrl = url
                    installApp()
                } else {
                    showWrongfileTypeAlert = true
                }
            }.help("playapp.add.help")
    }

    private func installApp() {
        Installer.install(ipaUrl: uif.ipaUrl!, returnCompletion: { (_) in
            DispatchQueue.main.async {
                AppsVM.shared.fetchApps()
                NotifyService.shared.notify(NSLocalizedString("notification.appInstalled", comment: ""),
                                            NSLocalizedString("notification.appInstalled.message", comment: ""))
            }
        })
    }

    private func selectFile() {
        NSOpenPanel.selectIPA { (result) in
            if case let .success(url) = result {
                uif.ipaUrl = url
                installApp()
            }
        }
    }

}
