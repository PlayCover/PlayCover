//
//  Downloader.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/26/1401 AP.
//

import Foundation
import CryptoKit
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
        if installVM.inProgress {
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
                }
            }

            proceedDownload()
        }
    }

    func cancel() {
        downloader.cancelAllDownloads()

        downloadVM.next(.canceled, 0.95, 1.0)
        downloadVM.storeAppData = nil
    }

    private func checksumAlert(originalSum: String, givenSum: String, completion: @escaping(Bool) -> Void) {
        Task { @MainActor in
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("playapp.download.differentChecksum", comment: "")
            alert.informativeText = String(
                format: NSLocalizedString("playapp.download.differentChecksumDesc", comment: ""),
                arguments: [originalSum, givenSum]
            )
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("button.Proceed", comment: ""))
            alert.addButton(withTitle: NSLocalizedString("button.Cancel", comment: ""))

            completion(alert.runModal() == .alertFirstButtonReturn)
        }
    }

    private func verifyChecksum(checksum: String?, file: URL?, completion: @escaping(Bool) -> Void) {
        Task {
            if let originalSum = self.downloadVM.storeAppData?.checksum, !originalSum.isEmpty, let fileURL = file {
                do {
                    let sha256 = SHA256.hash(data: try Data(contentsOf: fileURL))
                                       .map { String(format: "%02hhx", $0) }
                                       .joined()

                    if originalSum != sha256 {
                        checksumAlert(originalSum: originalSum, givenSum: sha256, completion: completion)
                        return
                    }
                } catch {
                    print("Error in calculating sha256sum: \(error)")
                }
            }

            completion(true)
        }
    }

    private func proceedDownload() {
        self.downloadVM.storeAppData = self.app
        self.downloadVM.next(.downloading, 0.0, 0.7)

        var tmpDir: URL?
        do {
            tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                 in: .userDomainMask,
                                                 appropriateFor: URL(fileURLWithPath: "/Users"),
                                                 create: true)

            if let tmpDir = tmpDir, let url = url {
                downloader.addDownload(url: url,
                                       destinationURL: tmpDir,
                                       onProgress: { progress in
                    // progress is a Float
                    self.downloadVM.progress = Double(progress)
                }, onCompletion: { error, fileURL in
                    self.downloadVM.next(.integrity, 0.7, 0.95)

                    if let error = error {
                        self.downloadVM.next(.failed, 0.95, 1.0)
                        self.downloadVM.storeAppData = nil
                        return Log.shared.error(error)
                    }

                    self.verifyChecksum(checksum: self.downloadVM.storeAppData?.checksum, file: fileURL) { completing in
                        self.downloadVM.next(completing ? .finish : .failed, 0.95, 1.0)
                        if completing {
                            Task { @MainActor in
                                self.proceedInstall(fileURL)
                            }
                        }
                    }
                })
            }
        } catch {
            self.downloadVM.next(.failed, 0.95, 1.0)

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
