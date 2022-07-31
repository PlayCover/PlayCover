//
//  NavView.swift
//  PlayCover
//

import Foundation
import SwiftUI
import Cocoa

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
