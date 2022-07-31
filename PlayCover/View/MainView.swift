//
//  NavView.swift
//  PlayCover
//

import Foundation
import SwiftUI
import Cocoa

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
        TextField(NSLocalizedString("search.search", comment: ""), text: $search)
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
    @Binding public var xcodeCliInstalled: Bool

    var body: some View {
        if apps.updatingApps { ProgressView() } else {
            ZStack(alignment: .bottom) {
                AppsView(bottomPadding: $bottomHeight, xcodeCliInstalled: $xcodeCliInstalled)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).environmentObject(AppsVM.shared)
            }
            // TODO: Toast
            /*.toast(isPresenting: $showToast) {
                AlertToast(type: .regular, title: NSLocalizedString("logs.copied", comment: ""))
            }*/
            .sheet(isPresented: $showSetup) {
                SetupView()
            }
            .alert(NSLocalizedString("alert.moveAppToApplications",
                                     comment: ""), isPresented: $integrity.integrityOff) {
                Button("alert.moveAppToApplications.move", role: .cancel) {
                    integrity.moveToApps()
                }
            }
        }
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    @State static var xcodeCliInstalled = true
	static var previews: some View {
		MainView(xcodeCliInstalled: $xcodeCliInstalled)
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
