//
//  Downloader.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/26/1401 AP.
//

import Foundation

// swiftlint:disable function_body_length
func downloadApp(_ url: URL,
                 _ app: StoreAppData,
                 _ downloadVM: DownloadVM,
                 _ warning: String?) {

    var observation: NSKeyValueObservation?

    if let warningMessage = warning {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString(warningMessage, comment: "")
        alert.informativeText = String(format: NSLocalizedString("ipaLibrary.alert.download",
                                                                 comment: ""),
                                       arguments: [app.name])
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("button.Yes", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("button.No", comment: ""))

        if alert.runModal() == .alertSecondButtonReturn {
            return
        }
    }

    if !downloadVM.downloading && !InstallVM.shared.installing {
        lazy var urlSession = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        let downloadTask = urlSession.downloadTask(with: url, completionHandler: { url, urlResponse, error in
            observation?.invalidate()
            downloadComplete(url, urlResponse, error)
        })

        observation = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                downloadVM.progress = progress.fractionCompleted
            }
        }

        downloadTask.resume()
        downloadVM.downloading = true
        downloadVM.progress = 0
        downloadVM.storeAppData = app
    } else {
        Log.shared.error(PlayCoverError.waitDownload)
    }
    func downloadComplete(_ url: URL?, _ urlResponce: URLResponse?, _ error: Error?) {
        if error != nil {
            Log.shared.error(error!)
        }
        if let url = url {
            var tmpDir: URL?

            do {
                tmpDir = try FileManager.default.url(for: .itemReplacementDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: URL(fileURLWithPath: "/Users"),
                                                     create: true)

                let tmpIpa = tmpDir!.appendingPathComponent(app.bundleID)
                                    .appendingPathExtension("ipa")

                try FileManager.default.moveItem(at: url, to: tmpIpa)
                uif.ipaUrl = tmpIpa
                DispatchQueue.main.async {
                    Installer.install(ipaUrl: uif.ipaUrl!, export: false, returnCompletion: { _ in
                        FileManager.default.delete(at: tmpDir!)

                        AppsVM.shared.apps = []
                        AppsVM.shared.fetchApps()
                        StoreVM.shared.resolveSources()
                        NotifyService.shared.notify(
                            NSLocalizedString("notification.appInstalled", comment: ""),
                            NSLocalizedString("notification.appInstalled.message", comment: ""))
                    })
                }
            } catch {
                if let tmpDir = tmpDir {
                    FileManager.default.delete(at: tmpDir)
                }

                Log.shared.error(error)
            }
        }
        downloadVM.downloading = false
        downloadVM.progress = 0
//        downloadVM.storeAppData = nil
    }
}
