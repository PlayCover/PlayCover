//
//  Sparkle.swift
//  PlayCover
//
//  Created by Andrew Glaze on 7/17/22.
//  Copied from https://sparkle-project.org/documentation/programmatic-setup/
//

import SwiftUI
import Sparkle

// This view model class manages Sparkle's updater and publishes when new updates are allowed to be checked
final class UpdaterViewModel: ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    
    @Published var canCheckForUpdates = false
    
    init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        
        updaterController.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
    
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

// This additional view is needed for the disabled state on the menu item to work properly before Monterey.
// See https://stackoverflow.com/questions/68553092/menu-not-updating-swiftui-bug for more information
struct CheckForUpdatesView: View {
    @ObservedObject var updaterViewModel: UpdaterViewModel
    
    var body: some View {
        Button("Check for Updates…", action: updaterViewModel.checkForUpdates)
            .disabled(!updaterViewModel.canCheckForUpdates)
    }
}

class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    @AppStorage("betaUpdates")var betaUpdates = false
    
    func allowedChannels(for updater: SPUUpdater) -> Set<String> {
        if betaUpdates {
            return Set(["beta"])
        } else {
            return Set([])
        }
    }
}
