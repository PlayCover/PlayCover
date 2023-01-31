//
//  Downloader.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/26/1401 AP.
//

import Foundation

class DownloadApp {
    let url: URL?
    let app: StoreAppData?
    let warning: String?

    init(url: URL?, app: StoreAppData?, warning: String?) {
        self.url = url
        self.app = app
        self.warning = warning
        downloader.$progress.assign(to: &downloadVM.$progress)
    }

    let downloadVM = DownloadVM.shared
    let installVM = InstallVM.shared
    let downloader = FileDownlaoder.shared

    func start() {
        if !NetworkVM.isConnectedToNetwork() { return }
        if installVM.installing {
            Log.shared.error(PlayCoverError.waitInstallation)
        } else {
            if let warningMessage = warning {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString(warningMessage, comment: "")
                alert.informativeText = String(
                    format: NSLocalizedString("ipaLibrary.alert.download", comment: ""),
                    arguments: [app!.name]
                )
                alert.alertStyle = .warning
                alert.addButton(withTitle: NSLocalizedString("button.Yes", comment: ""))
                alert.addButton(withTitle: NSLocalizedString("button.No", comment: ""))

                if alert.runModal() == .alertSecondButtonReturn {
                    return
                } else {
                    proceedDownload()
                }
            } else {
                proceedDownload()
            }
        }
    }

    func cancel() {
        downloader.cancelDownload()
        downloadVM.downloading = false
        downloadVM.storeAppData = nil
    }

    private func proceedDownload() {
        self.downloadVM.storeAppData = self.app
        self.downloadVM.downloading = true

        Task {
            var tmpDir: URL?
            do {
                tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: URL(fileURLWithPath: "/Users"),
                                                     create: true)
                let filePath = tmpDir!.appendingPathComponent("\(app!.name).ipa")
                try await downloader.download(url: url!, filePath: filePath)
                proceedInstall(filePath)
            } catch {
                if let tmpDir = tmpDir {
                    FileManager.default.delete(at: tmpDir)
                }
                if error as? CancellationError == nil {
                    Log.shared.error(error)
                }
            }
            Task { @MainActor in
                downloadVM.downloading = false
                downloader.clearProgress()
            }
        }
    }

    private func proceedInstall(_ url: URL?) {
        if let url = url {
            uif.ipaUrl = url
            Installer.install(ipaUrl: uif.ipaUrl!, export: false, returnCompletion: { _ in
                Task { @MainActor in
                    FileManager.default.delete(at: url)
                    AppsVM.shared.fetchApps()
                    StoreVM.shared.resolveSources()
                    NotifyService.shared.notify(
                        NSLocalizedString("notification.appInstalled", comment: ""),
                        NSLocalizedString("notification.appInstalled.message", comment: ""))
                    self.downloadVM.storeAppData = nil
                }
            })
        }
    }
}
