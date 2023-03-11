//
//  AppIntegrity.swift
//  PlayCover
//

import Foundation

class AppIntegrity: ObservableObject {

    @Published var integrityOff: Bool = !AppIntegrity.insideAppsFolder

    func verifyAppIntegrity() {
        integrityOff = !AppIntegrity.insideAppsFolder
    }

    func moveToApps() {
        do {
            if let url = AppIntegrity.appUrl {
                FileManager.default.delete(at: AppIntegrity.expectedUrl)
                try FileManager.default.copyItem(at: url, to: AppIntegrity.expectedUrl)
                URL(fileURLWithPath: AppIntegrity.expectedUrl.path).openInFinder()
                FileManager.default.delete(at: url)
                    exit(0)
                }
            } catch {
                Log.shared.error(error)
        }
    }

    private static var appUrl: URL? {
        Bundle.main.resourceURL?.deletingLastPathComponent().deletingLastPathComponent()
    }

    private static var expectedUrl = URL(fileURLWithPath: "/Applications/PlayCover.app")

    private static var insideAppsFolder: Bool {
        if let url = appUrl {
            return url.path.contains("Xcode") || url.path.contains(expectedUrl.path)
        }
        return false
    }

}
