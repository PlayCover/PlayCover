//
//  IPA.swift
//  PlayCover
//

import Foundation

public class IPA {
    public let url: URL
    public private(set) var tmpDir: URL?

    public init(url: URL) {
        self.url = url
    }

    public func allocateTempDir() throws {
        tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                             in: .userDomainMask,
                                             appropriateFor: URL(fileURLWithPath: "/Users"),
                                             create: true)
    }

    public func releaseTempDir() {
        guard let workDir = tmpDir else {
            return
        }

        FileManager.default.delete(at: workDir)

        tmpDir = nil
    }

    public func removeQuarantine(_ execUrl: URL) throws {
        try Shell.run("/usr/bin/xattr", "-r", "-d", "com.apple.quarantine", execUrl.relativePath)
    }

    public func unzip() throws -> BaseApp {
        if let workDir = tmpDir {
            if try Shell.run("/usr/bin/unzip",
                             "-oq", url.path, "-d", workDir.path) == "" {
                return try Installer.fromIPA(detectingAppNameInFolder: workDir.appendingPathComponent("Payload"))
            } else {
                throw PlayCoverError.appCorrupted
            }
        } else {
            throw PlayCoverError.appCorrupted
        }
    }

    func packIPABack(app: URL) throws -> URL {
        let payload = app.deletingPathExtension().deletingLastPathComponent()
        let name = app.deletingPathExtension().lastPathComponent

        let newIpa = getDocumentsDirectory()
            .appendingEscapedPathComponent(name)
            .appendingPathExtension("ipa")

        try Shell.run("usr/bin/zip", "-r", newIpa.path, payload.path)

        return newIpa
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    enum Application {
        case base(BaseApp)
        case store(StoreAppData)
    }

    @MainActor
    func hasMacVersion(app: Application) async -> Bool {
        let bundleID: String
        let appID: Int
        switch app {
        case .base(let base):
            bundleID = base.info.bundleIdentifier
            let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleID)"
            let itunes: ITunesResponse? = await getITunesData(urlString)
            appID = itunes?.results.first?.trackId ?? 0
        case .store(let store):
            bundleID = store.bundleID
            let appLookup = store.itunesLookup
            let stringArray = appLookup.components(separatedBy: CharacterSet.decimalDigits.inverted)
            appID = Int(stringArray.last ?? "0") ?? 0
        }
        let noMacAlert = UserDefaults.standard.bool(forKey: "\(bundleID).noMacAlert")
        if PlayApp.MACOS_APPS.contains(bundleID), !noMacAlert {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("alert.error", comment: "")
            alert.informativeText = String(
             format: NSLocalizedString("macos.version", comment: "")
            )
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("alert.install.anyway", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("alert.open.appstore", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))
            let result = alert.runModal()
            switch result {
            case .alertFirstButtonReturn:
                UserDefaults.standard.set(true, forKey: "\(bundleID).noMacAlert")
            case .alertSecondButtonReturn:
                if appID != 0 {
                    guard let urlApp = URL(string:
                                            "itms-apps://apps.apple.com/app/id\(appID)")
                    else {return true}
                    NSWorkspace.shared.open(urlApp)
                }
                return true
            default:
                return true
            }
         }
        return false
    }
}
