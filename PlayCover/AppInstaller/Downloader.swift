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
    let url: URL
    let app: StoreAppData
    let completion: () -> Void

    init(url: URL, app: StoreAppData, completion: @escaping() -> Void) {
        self.url = url
        self.app = app
        self.completion = completion
    }

    let downloadVM = DownloadVM.shared
    let installVM = InstallVM.shared
    let downloader = DownloadManager.shared

    func start() {
        guard NetworkVM.isConnectedToNetwork() else {
            return
        }

        if url.isFileURL {
            proceedInstall(url, deleteIPA: false)
        } else {
            proceedDownload()
        }
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
            if let originalSum = checksum, !originalSum.isEmpty, let fileURL = file {
                if let sha256 = fileURL.sha256, originalSum != sha256 {
                    checksumAlert(originalSum: originalSum, givenSum: sha256, completion: completion)
                    return
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
            downloader.addDownload(url: url,
                                   destinationURL: tmpDir!,
                                   onProgress: { progress in
                // progress is a Float
                self.downloadVM.progress = Double(progress)
            }, onCompletion: { error, fileURL in
                self.downloadVM.next(.integrity, 0.7, 0.95)

                guard error == nil else {
                    self.downloadVM.next(.failed, 0.95, 1.0)
                    self.downloadVM.storeAppData = nil
                    return Log.shared.error(error!)
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
        } catch {
            self.downloadVM.next(.failed, 0.95, 1.0)

            if let tmpDir = tmpDir {
                FileManager.default.delete(at: tmpDir)
            }
            Log.shared.error(error)
        }
    }

    private func proceedInstall(_ url: URL?, deleteIPA: Bool = true) {
        if let url = url {
            QueuesVM.shared.addInstallItem(ipa: url, deleteIpa: true)
            self.downloadVM.storeAppData = nil
            self.completion()
        }
    }
}
