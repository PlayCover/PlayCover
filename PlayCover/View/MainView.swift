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

struct SearchView: View {

    @State private var search: String = ""
    @State private var isEditing = false
    @Environment(\.colorScheme) var colorScheme

    var body : some View {
        TextField(NSLocalizedString("Search...", comment: ""), text: $search)
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
                } else {
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
                            }, label: {
                            Image(systemName: "multiply.circle.fill")
                                .padding(.trailing, 16)
                        }).buttonStyle(PlainButtonStyle())
                    }
                }
            )
    }
}

struct MainView: View {
	@Environment(\.openURL) var openURL
    @EnvironmentObject var install: InstallVM
    @EnvironmentObject var apps: AppsVM
    @EnvironmentObject var integrity: AppIntegrity

    @State var showSetup = false
    @State var noticesExpanded = false
    @State var bottomHeight: CGFloat = 0

    @Binding var showToast: Bool
    @Binding public var xcodeCliInstalled: Bool

    var body: some View {
        if apps.updatingApps { ProgressView() } else {
            ZStack(alignment: .bottom) {
                AppsView(bottomPadding: $bottomHeight, xcodeCliInstalled: $xcodeCliInstalled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).environmentObject(AppsVM.shared)

                VStack(alignment: .leading, spacing: 0) {
                    if install.installing {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {

                                    InstallProgress().environmentObject(install).padding(.bottom)
                            }.padding().frame(maxWidth: .infinity)

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
                                    Image(systemName: "chevron.up")
                                        .rotationEffect(Angle(degrees: noticesExpanded ? 180 : 0))
                                }
                                Spacer()
                                if !SystemConfig.isPlaySignActive {
                                    HStack {
                                        Button("Problems logging in?") { showSetup = true }
                                            .buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
                                    }
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
                            Spacer()
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
                .overlay(GeometryReader { geometry in
                    Text("")
                        .onChange(of: geometry.size.height) { height in bottomHeight = height }
                        .onAppear {
                            print("Bottom height: \(geometry.size.height)")
                            bottomHeight = geometry.size.height
                        }
                })
            }
            .toast(isPresenting: $showToast) {
                AlertToast(type: .regular, title: NSLocalizedString("Logs copied!", comment: ""))
            }
            .sheet(isPresented: $showSetup) {
                SetupView()
            }
            .alert(NSLocalizedString("PlayCover must be in the Applications folder. " +
                                     "Press the button below to let PlayCover move itself to /Applications.",
                                     comment: ""), isPresented: $integrity.integrityOff) {
                Button("Move to /Applications", role: .cancel) {
                    integrity.moveToApps()
                }
            }
        }
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    @State static var showToast = false
    @State static var xcodeCliInstalled = true
	static var previews: some View {
		MainView(showToast: $showToast, xcodeCliInstalled: $xcodeCliInstalled)
			.padding()
			.environmentObject(InstallVM.shared)
			.environmentObject(AppsVM.shared)
			.environmentObject(AppIntegrity())
			.frame(minWidth: 600, minHeight: 650)
			.onAppear {
				UserDefaults.standard.register(defaults: ["ShowLinks": true])
				SoundDeviceService.shared.prepareSoundDevice()
				NotifyService.shared.allowNotify()
			}
			.padding(-15)
	}
}
