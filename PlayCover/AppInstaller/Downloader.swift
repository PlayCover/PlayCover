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
/// `}`
///  Use `downloader.configuration = DownloadManagerConfig()` in
///  `DownloadApp` class before `downloader.addDownload` to apply
///  More details: https://github.com/shapedbyiris/download-manager/blob/master/README.md

class DownloadApp {
    let url: URL?
    let app: StoreAppData?
    let warning: String?

    init(url: URL?, app: StoreAppData?, warning: String?) {
        self.url = url
        self.app = app
        self.warning = warning
    }

    let downloadVM = DownloadVM.shared
    let installVM = InstallVM.shared
    let downloader = DownloadManager.shared

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
        downloader.cancelAllDownloads()
        downloadVM.downloading = false
        downloadVM.progress = 0
        downloadVM.storeAppData = nil
    }

    private func proceedDownload() {
        self.downloadVM.storeAppData = self.app
        self.downloadVM.downloading = true
        var tmpDir: URL?
        do {
            tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: URL(fileURLWithPath: "/Users"),
                                                 create: true)
            downloader.addDownload(url: url!,
                                   destinationURL: tmpDir!,
                                   onProgress: { progress in
                // progress is a Float
                self.downloadVM.progress = Double(progress)
            }, onCompletion: { error, fileURL in
                guard error == nil else {
                    self.downloadVM.downloading = false
                    self.downloadVM.progress = 0
                    self.downloadVM.storeAppData = nil
                    return Log.shared.error(error!)
                }
                self.downloadVM.downloading = false
                self.downloadVM.progress = 0
                self.proceedInstall(fileURL)
            })
        } catch {
            if let tmpDir = tmpDir {
                FileManager.default.delete(at: tmpDir)
            }
            Log.shared.error(error)
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
