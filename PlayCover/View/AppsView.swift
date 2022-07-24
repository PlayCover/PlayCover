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

    @EnvironmentObject var appVm: AppsVM

    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 10)]

	@State private var alertTitle = ""

	@State private var alertText = ""

	@State private var alertBtn = ""

	@State private var alertAction : (() -> Void) = {}

	@State private var showAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SearchView().padding(.horizontal, 20).padding(.vertical, 8)
            }
			if !shell.isXcodeCliToolsInstalled {
				VStack(spacing: 12) {
					Text("You need to install Xcode Commandline tools and restart this App.")
						.font(.title3)
					Button("Install") {
						do {
							_ = try shell.sh("xcode-select --install")
							alertTitle = NSLocalizedString("Xcode tools installation succeeded", comment: "")
							alertBtn = NSLocalizedString("Close", comment: "")
							alertText = NSLocalizedString("Please follow the given instructions, and restart the App.", comment: "")
							alertAction = {
								exit(0)
							}
							showAlert = true
						} catch {
							alertTitle = NSLocalizedString("Xcode tools intallation failed", comment: "")
							alertBtn = NSLocalizedString("OK", comment: "")
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
				ScrollView {
					LazyVGrid(columns: gridLayout, spacing: 10) {
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
					.padding(.top, 16).padding(.bottom, bottomPadding + 16)
                    .animation(.spring())
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
            Text("Add app").padding(.horizontal)
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
                Alert(title: Text("Wrong file type"),
                      message: Text("Choose an .ipa file"), dismissButton: .default(Text("OK")))
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
            }.help("Drag or open an app file to install. IPAs from Configurator or iMazing won't work! " +
                   "You should get decrypted IPAs, either from the top right button, Discord, AppDb," +
                   " or a jailbroken device.")
    }

    private func installApp() {
        Installer.install(ipaUrl: uif.ipaUrl!, returnCompletion: { (_) in
            DispatchQueue.main.async {
                AppsVM.shared.fetchApps()
                NotifyService.shared.notify(NSLocalizedString("App installed!", comment: ""),
                                            NSLocalizedString("Check it out in 'My Apps'", comment: ""))
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
