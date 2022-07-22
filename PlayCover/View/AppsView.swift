//
//  AppsLibraryView.swift
//  PlayCover
//

import Foundation

import SwiftUI
import Cocoa

struct AppsView : View {
    @Binding public var bottomPadding: CGFloat
    
    @EnvironmentObject var vm : AppsVM
    
    @State private var gridLayout = [GridItem(.adaptive(minimum: 150, maximum: 150), spacing: 10)]

	@State private var alertTitle = ""

	@State private var alertText = ""

	@State private var alertBtn = ""

	@State private var alertAction : (() -> Void) = {}

	@State private var showAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SearchView().padding(.leading, 20).padding(.trailing, 10).padding(.vertical, 8)
                ExportView().environmentObject(InstallVM.shared)
                Button(NSLocalizedString("topBar.downloadMoreApps", comment: "")) {
                    if let url = URL(string: "https://ipa.playcover.workers.dev/0:/") {
                        NSWorkspace.shared.open(url)
                    }
                }.buttonStyle(OutlineButton()).controlSize(.large).help("topBar.downloadMoreApps.help")
                    .padding(.trailing, 30)
            }
			if !sh.isXcodeCliToolsInstalled {
				VStack(spacing: 12) {
					Text("xcode.needToInstall")
						.font(.title3)
					Button("button.Install") {
						do {
							_ = try sh.sh("xcode-select --install")
							alertTitle = NSLocalizedString("alert.xcodeToolsInstallSucceeded", comment: "")
							alertBtn = NSLocalizedString("button.Close", comment: "")
							alertText = NSLocalizedString("alert.followInstructionAndRestartApp", comment: "")
							alertAction = {
								exit(0)
							}
							showAlert = true
						} catch {
							alertTitle = NSLocalizedString("xcode.installFailed", comment: "")
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
				ScrollView() {
					LazyVGrid(columns: gridLayout, spacing: 10) {
						ForEach(vm.apps, id:\.id) { app in
							if app.type == BaseApp.AppType.add {
								AppAddView().environmentObject(InstallVM.shared)
							} else if app.type == .app{
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

struct AppAddView : View {
    
    @State var isHover : Bool = false
    @State var showWrongfileTypeAlert : Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var install : InstallVM
    
    func elementColor(_ dark : Bool) -> Color {
        return isHover ? Colr.controlSelect().opacity(0.3) : Color.black.opacity(0.0)
    }
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: "plus.square")
                .font(.system(size: 38.0, weight: .thin))
                .frame(width: 64, height: 68).padding(.top).foregroundColor(
                    install.installing ? Color.gray : Color.accentColor)
            Text("app.add").padding(.horizontal).frame(width: 150, height: 50).padding(.bottom).lineLimit(nil).foregroundColor( install.installing ? Color.gray : Color.accentColor).minimumScaleFactor(0.8).multilineTextAlignment(.center)
        }.background(colorScheme == .dark ? elementColor(true) : elementColor(false))
            .cornerRadius(16.0)
            .frame(width: 150, height: 150).onHover(perform: { hovering in
                isHover = hovering
            }).alert(isPresented: $showWrongfileTypeAlert) {
                Alert(title: Text("alert.wrongFileType"), message: Text("alert.wrongFileType"), dismissButton: .default(Text("button.OK")))
            }
            .onTapGesture {
                if install.installing{
                    isHover = false
                    Log.shared.error(PlayCoverError.waitInstallation)
                } else{
                    isHover = false
                    selectFile()
                }
                
            }.onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
                if install.installing{
                    Log.shared.error(PlayCoverError.waitInstallation)
                    return false
                } else if let item = items.first {
                    if let identifier = item.registeredTypeIdentifiers.first {
                        if identifier == "public.url" || identifier == "public.file-url" {
                            item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                                DispatchQueue.main.async {
                                    if let urlData = urlData as? Data {
                                        let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                        if urll.pathExtension == "ipa"{
                                            uif.ipaUrl = urll
                                            installApp()
                                        } else{
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
            .handlesExternalEvents(preferring: Set(arrayLiteral: "{path of URL?}"), allowing: Set(arrayLiteral: "*")) // // activate existing window if exists
            .onOpenURL{url in
                if url.pathExtension == "ipa"{
                    uif.ipaUrl = url
                    installApp()
                } else{
                    showWrongfileTypeAlert = true
                }
            }.help("app.add.help")
    }
    
    private func installApp(){
        Installer.install(ipaUrl : uif.ipaUrl! , returnCompletion: { (app) in
            DispatchQueue.main.async {
                AppsVM.shared.fetchApps()
                NotifyService.shared.notify(NSLocalizedString("notification.appInstalled", comment: ""), NSLocalizedString("notification.appInstalled.message", comment: ""))
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

struct ExportView : View {
    
    @State var isHover : Bool = false
    @State var showWrongfileTypeAlert : Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject var install : InstallVM
    
    func elementColor(_ dark : Bool) -> Color {
        return isHover ? Colr.controlSelect().opacity(0.3) : Color.black.opacity(0.0)
    }
    
    var body: some View {
        
        Button("topBar.exportToSideloady") {
            if install.installing {
                isHover = false
                Log.shared.error(PlayCoverError.waitInstallation)
            } else{
                isHover = false
                selectFile()
            }
        }
        .buttonStyle(OutlineButton())
        .controlSize(.large)
        .help("topBar.exportToSideloady.help").background(colorScheme == .dark ? elementColor(true) : elementColor(false))
        .alert(isPresented: $showWrongfileTypeAlert) {
            Alert(title: Text("alert.wrongFileType"), message: Text("alert.wrongFileType.message"), dismissButton: .default(Text("button.OK")))
        }.onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
            if install.installing{
                Log.shared.error(PlayCoverError.waitInstallation)
                return false
            } else if let item = items.first {
                if let identifier = item.registeredTypeIdentifiers.first {
                    if identifier == "public.url" || identifier == "public.file-url" {
                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                            DispatchQueue.main.async {
                                if let urlData = urlData as? Data {
                                    let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                    if urll.pathExtension == "ipa"{
                                        uif.ipaUrl = urll
                                        exportIPA()
                                    } else{
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
        .handlesExternalEvents(preferring: Set(arrayLiteral: "{path of URL?}"), allowing: Set(arrayLiteral: "*")) // // activate existing window if exists
        .onOpenURL{url in
            if url.pathExtension == "ipa"{
                uif.ipaUrl = url
                exportIPA()
            } else{
                showWrongfileTypeAlert = true
            }
        }.help("app.add.help")
    }
    
    private func exportIPA(){
        Installer.exportForSideloadly(ipaUrl : uif.ipaUrl! , returnCompletion: { (ipa) in
            DispatchQueue.main.async {
                ipa?.showInFinder()
                NSWorkspace.shared.open([ipa!], withAppBundleIdentifier: "com.sideloadly.sideloadly", options: NSWorkspace.LaunchOptions.withErrorPresentation, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
            }
        })
    }
    
    private func selectFile() {
        NSOpenPanel.selectIPA { (result) in
            if case let .success(url) = result {
                uif.ipaUrl = url
                exportIPA()
            }
        }
    }
    
}


