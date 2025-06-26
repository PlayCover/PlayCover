//
//  VersionCheck.swift
//  PlayCover
//
//  Created by Edoardo C. on 30/04/25.
//

class VersionCheck {
    static let shared = VersionCheck()
    @MainActor
    func checkUpdateAlert(app: SourceAppsData) async -> Bool {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("alert.version.title", comment: "")
        alert.informativeText = String(
            format: NSLocalizedString("alert.version.text", comment: ""), "\(app.name)"
        )
        alert.icon = NSImage(
            systemSymbolName: "square.and.arrow.down.fill",
            accessibilityDescription: nil
        )
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("alert.start.anyway", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("ipaLibrary.download", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))
        let result = alert.runModal()
        switch result {
        case .alertFirstButtonReturn:
            return false
        case .alertSecondButtonReturn:
            if let url = URL(string: app.link) {
                if DownloadVM.shared.inProgress {
                    Log.shared.error(PlayCoverError.waitDownload)
                } else {
                    let redirectHandler = RedirectHandler(url: url) // checking page redirect
                    DownloadApp(url: redirectHandler.getFinal(), app: app, warning: nil).start()
                }
            }
            return true
        default:
            return true
        }
    }

    func checkNewVersion(myApp: PlayApp) async -> Bool {
        await StoreVM.shared.awaitResolveSources()
        let storeApp = StoreVM.shared.sourcesApps
        if let app = storeApp.first(where: {$0.bundleID == myApp.info.bundleIdentifier}) {
            if myApp.info.bundleVersion.compare(app.version, options: .numeric) == .orderedAscending {
                return await checkUpdateAlert(app: app)
            }
        }
        return false
    }
}
