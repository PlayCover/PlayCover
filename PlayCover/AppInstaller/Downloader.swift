//
//  Downloader.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/26/1401 AP.
//

import Foundation
import DownloadManager

/// DownloaderManager can be configured through this struct, default values are as the same as below
/// `public struct DownloadManagerConfig {`
///    `public var maximumRetries = 3`
///    `public var exponentialBackoffMultiplier = 10`
///    `public var usesNotificationCenter = false`
///    `public var showsLocalNotifications = false`
///    `public var logVerbosity: LogVerbosity = .none
/// `}
///  Use `downloader.configuration = DownloadManagerConfig()` in
///  `DownloadApp` class before `downloader.addDownload` to apply
///  More detail: https://github.com/shapedbyiris/download-manager/blob/master/README.md

class DownloadApp {
    let url: URL
    let app: StoreAppData
    let warning: String?

    init(url: URL, app: StoreAppData, warning: String?) {
        self.url = url
        self.app = app
        self.warning = warning
    }

    let dlVM = DownloadVM.shared
    let inVM = InstallVM.shared
    let downloader = DownloadManager.shared

    func start() {
        if let warningMessage = warning {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString(warningMessage, comment: "")
            alert.informativeText = String(
                format: NSLocalizedString("ipaLibrary.alert.download", comment: ""),
                arguments: [app.name]
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

    func cancel() {
        downloader.cancelAllDownloads()
        dlVM.downloading = false
        dlVM.progress = 0
        dlVM.storeAppData = nil
    }

    private func proceedDownload() {
        if dlVM.downloading && inVM.installing {
            Log.shared.error(PlayCoverError.waitDownload)
        } else {
            let path = NSURL.fileURL(withPathComponents: [NSTemporaryDirectory(), app.bundleID])
            downloader.addDownload(url: url,
                                   destinationURL: path!,
                                   onProgress: { progress in
                self.dlVM.storeAppData = self.app
                self.dlVM.downloading = true
                // progress is a Float
                self.dlVM.progress = Double(progress)
            }, onCompletion: { error, fileURL in
                guard error == nil else {
                    self.dlVM.downloading = false
                    self.dlVM.progress = 0
                    self.dlVM.storeAppData = nil
                    return Log.shared.error(error!)
                }
                self.dlVM.downloading = false
                self.dlVM.progress = 0
                self.proceedInstall(fileURL)
            })
        }
    }

    private func proceedInstall(_ url: URL?) {
        if let url = url {
            var tmpDir: URL?
            do {
                tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: URL(fileURLWithPath: "/Users"),
                                                     create: true)
                let tmpIpa = tmpDir!
                    .appendingPathComponent(app.bundleID)
                    .appendingPathExtension("ipa")

                try FileManager.default.moveItem(at: url, to: tmpIpa)
                uif.ipaUrl = tmpIpa
                Installer.install(ipaUrl: uif.ipaUrl!, export: false, returnCompletion: { _ in
                    DispatchQueue.main.async {
                        FileManager.default.delete(at: tmpDir!)
                        AppsVM.shared.apps = []
                        AppsVM.shared.fetchApps()
                        StoreVM.shared.resolveSources()
                        NotifyService.shared.notify(
                            NSLocalizedString("notification.appInstalled", comment: ""),
                            NSLocalizedString("notification.appInstalled.message", comment: ""))
                        self.dlVM.storeAppData = nil
                    }
                })
            } catch {
                if let tmpDir = tmpDir {
                    FileManager.default.delete(at: tmpDir)
                }
                Log.shared.error(error)
            }
        }
    }
}
