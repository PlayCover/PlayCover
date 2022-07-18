//
//  NavView.swift
//  PlayCover
//

import Foundation
import SwiftUI
import Cocoa
import AlertToast

extension NSTextField {
        open override var focusRingType: NSFocusRingType {
                get { .none }
                set { }
        }
}

struct SearchView : View {
    
    @State private var search : String = ""
    @State private var isEditing = false
    @Environment(\.colorScheme) var colorScheme
    
    var body : some View {
        TextField("Search...", text: $search)
            .padding(7)
            .padding(.horizontal, 25)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .font(Font.system(size: 16))
            .padding(.horizontal, 10)
            .onChange(of: search, perform: { value in
                uif.searchText = value
                AppsVM.shared.fetchApps()
                if value.isEmpty {
                    isEditing = false
                } else{
                    isEditing = true
                }
            })
            .textFieldStyle(PlainTextFieldStyle())
            .frame(maxWidth: .infinity).overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                    if isEditing {
                            Button(action: {
                            self.search = ""
                        }) {
                            Image(systemName: "multiply.circle.fill")
                                .padding(.trailing, 16)
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
            )
    }
}

struct MainView: View {
	@Environment(\.openURL) var openURL
    @EnvironmentObject var update : UpdateService
    @EnvironmentObject var install : InstallVM
    @EnvironmentObject var apps : AppsVM
    @EnvironmentObject var integrity : AppIntegrity

    @State var showSetup = false
    @State var noticesExpanded = false
    @State var bottomHeight: CGFloat = 0
    
    @State private var showToast = false
    
    var body: some View {
        if apps.updatingApps { ProgressView() }
        else {
            ZStack(alignment: .bottom) {
                AppsView(bottomPadding: $bottomHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).environmentObject(AppsVM.shared)
                
                VStack(alignment: .leading, spacing: 0) {
                    if install.installing {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {
                                
                                    InstallProgress().environmentObject(install).padding(.bottom)
                            }.padding().frame(maxWidth : .infinity)
                            
                        }
                    }
                    
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Notices").font(.headline).help("Important news and announcements")
                                Button {
                                    withAnimation { noticesExpanded.toggle() }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(Angle(degrees: noticesExpanded ? 180 : 0))
                                }
                            }
                            Text(StoreApp.notice)
                                .font(.body)
                                .frame(minHeight: 0, maxHeight: noticesExpanded ? nil : 0, alignment: .top)
                                .animation(.spring(), value: noticesExpanded)
                                .clipped()
                                .padding(.top, noticesExpanded ? 8 : 0)
                        }
                        
                        HStack(spacing: 12) {
                            Link("Join Discord Server", destination: URL(string: "https://discord.gg/rMv5qxGTGC")!)
                                .help("If you have some problem you always can visit our friendly community.")
                                .foregroundColor(.accentColor)
                            Spacer()
                                if !SystemConfig.isPlaySignActive {
                                    Text("Having problems logging into apps?").font(.title3)
                                    Button("Enable PlaySign") { showSetup = true }
                                        .buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
                                    Spacer()
                                }
                            Button(action: {
                                Log.shared.logdata.copyToClipBoard()
                                showToast.toggle()
                            }) {
                                Text("Copy logs")
                            }.controlSize(.large)
                            if !update.updateLink.isEmpty {
                                Button(action: { NSWorkspace.shared.open(URL(string: update.updateLink)!) }) {
                                    HStack {
                                        Image(systemName: "arrow.down.square.fill")
                                        Text("Update app")
                                    }
                                }.buttonStyle(UpdateButton()).controlSize(.large)
                            }
                        }.frame(maxWidth: .infinity)
						#if DEBUG
						Divider()
						HStack(spacing: 12) {
							Button("Crash") { fatalError("Crash was triggered") }
								.buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
						}.frame(maxWidth: .infinity)
						#endif
                    }.padding()
                }
                .background(.regularMaterial)
                .overlay(GeometryReader { geomatry in
                    Text("")
                        .onChange(of: geomatry.size.height) { v in bottomHeight = v }
                        .onAppear {
                            print("Bottom height: \(geomatry.size.height)")
                            bottomHeight = geomatry.size.height
                        }
                })
            }
            .toast(isPresenting: $showToast) {
                AlertToast(type: .regular, title: "Logs copied!")
            }
            .sheet(isPresented: $showSetup) {
                SetupView()
            }
            .alert("PlayCover must be in the Applications folder. Press the button below to let PlayCover move itself to /Applications.", isPresented: $integrity.integrityOff) {
                Button("Move to /Applications", role: .cancel) {
                    integrity.moveToApps()
                }
            }
        }
    }
}

struct Previews_MainView_Previews: PreviewProvider {
	static var previews: some View {
		MainView()
			.padding()
			.environmentObject(UpdateService.shared)
			.environmentObject(InstallVM.shared)
			.environmentObject(AppsVM.shared)
			.environmentObject(AppIntegrity())
			.frame(minWidth: 600, minHeight: 650)
			.onAppear {
				UserDefaults.standard.register(defaults: ["ShowLinks" : true])
				SoundDeviceService.shared.prepareSoundDevice()
				UpdateService.shared.checkUpdate()
				NotifyService.shared.allowNotify()
			}
			.padding(-15)
	}
}
