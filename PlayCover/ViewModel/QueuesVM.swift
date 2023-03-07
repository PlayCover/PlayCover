//
//  QueuesVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 2/13/23.
//

import Foundation
import DownloadManager

struct InstallData: Equatable {
    let ipa: URL
    let delete: Bool
}

class QueuesVM: ObservableObject {
    public static let shared = QueuesVM()

    // URL of ipa to install and if ipa should be deleted
    @Published public private(set) var installQueueItems: [InstallData] = []

    // App data of ipa to download
    @Published public private(set) var downloadQueueItems: [StoreAppData] = []

    @Published public private(set) var currentInstallItem: InstallData?

    @Published public private(set) var currentDownloadItem: StoreAppData?

    private func installItem() {
        if let item = currentInstallItem {
            self.installQueueItems.removeAll(where: { $0 == item }) // Remove item from queue

            Installer.install(ipaUrl: item.ipa, export: false, returnCompletion: { _ in
                Task { @MainActor in
                    // Remove ipa if it is specificed to be removed
                    if item.delete {
                        FileManager.default.delete(at: item.ipa)
                    }

                    AppsVM.shared.fetchApps()
                    StoreVM.shared.resolveSources()

                    NotifyService.shared.notify(
                        NSLocalizedString("notification.appInstalled", comment: ""),
                        NSLocalizedString("notification.appInstalled.message", comment: ""))

                    // Check if there is another item in the install queue
                    if let nextItem = self.installQueueItems.first {
                        // Assign current install item to the next member in the queue
                        self.currentInstallItem = nextItem

                        self.installItem() // Run this function again for the new item
                    } else {
                        self.currentInstallItem = nil
                    }
                }
            })
        }
    }

    private func downloadItem() {
        if let item = currentDownloadItem, let url = URL(string: item.link) {
            self.downloadQueueItems.removeAll(where: { $0 == item }) // Remove item from queue

            DownloadApp(url: url, app: item, completion: {
                // Check if there is another item in the download queue
                if let nextItem = self.downloadQueueItems.first {
                    self.currentDownloadItem = nextItem
                    self.downloadItem() // Run function again
                } else {
                    self.currentDownloadItem = nil
                }
            }).start()
        }
    }

    @discardableResult
    public func addInstallItem(ipa: URL, deleteIpa: Bool = false) -> Bool {
        // Make sure item is not already in queue
        guard installQueueItems.firstIndex(where: { $0.ipa == ipa }) == nil && currentInstallItem?.ipa != ipa else {
            alreadyInQueueAlert()
            return false
        }

        guard currentInstallItem == nil else { // Ensure there is currently not an install in progress
            installQueueItems.append(InstallData(ipa: ipa, delete: deleteIpa)) // Add item to queue

            // Only show toast if there is already an item in queue
            ToastVM.shared.showToast(toastType: .notice,
                                     toastDetails: String(format: NSLocalizedString("queue.toast.installAdded",
                                                                                    comment: ""),
                                                          arguments: [ipa.lastPathComponent]))

            return true // Item has still been appened to queue successfully
        }

        currentInstallItem = InstallData(ipa: ipa, delete: deleteIpa) // Set current install item to added item

        installItem() // Start consuming the queue

        return true
    }

    @discardableResult
    public func addDownloadItem(app: StoreAppData) -> Bool {
        // Make sure item is not already in queue
        guard downloadQueueItems.firstIndex(where: { $0 == app }) == nil && currentDownloadItem != app else {
            alreadyInQueueAlert()
            return false
        }

        guard currentDownloadItem == nil else { // Ensure there is currently not a download in progress
            downloadQueueItems.append(app) // Add item to queue

            // Only show toast if there is already an item in queue
            ToastVM.shared.showToast(toastType: .notice,
                                     toastDetails: String(format: NSLocalizedString("queue.toast.downloadAdded",
                                                                                    comment: ""),
                                                          arguments: [app.name]))

            return true // Item has still been appened to queue successfully
        }

        currentDownloadItem = app // Set current download item to added item

        downloadItem() // Start consuming queue

        return true
    }

    @discardableResult
    public func removeInstallItem(ipa: URL) -> Bool {
        // Ensures that the item exists in the array
        guard let currentInstallItem = currentInstallItem else {
            notInQueueAlert()
            return false
        }

        // Cancel install if it is currently in progress
        if currentInstallItem.ipa == ipa {
            Installer.cancelInstall()
        } else { // Otherwise just remove it from queue
            installQueueItems.removeAll(where: { $0.ipa == ipa })
        }

        return true
    }

    @discardableResult
    public func removeDownloadItem(app: StoreAppData) -> Bool {
        if let idx = downloadQueueItems.firstIndex(of: app) { // Ensures the item is in the queue
            downloadQueueItems.remove(at: idx) // Remove item from queue
        } else if currentDownloadItem == app, let url = URL(string: app.link) { // Checks if it is being downloaded
            DownloadManager.shared.cancelDownload(withURL: url) // Cancel the download
            DownloadVM.shared.next(.canceled, 0.95, 1.0)
            DownloadVM.shared.storeAppData = nil

            // Check if there is another item in the download queue
            if let nextItem = self.downloadQueueItems.first {
                self.currentDownloadItem = nextItem
                self.downloadItem() // Download next item
            } else {
                self.currentDownloadItem = nil
            }
        } else {
            notInQueueAlert()
            return false
        }

        return true
    }

    private func alreadyInQueueAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("queue.alert.exists", comment: "")
        alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
        alert.runModal()
    }

    private func notInQueueAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("queue.alert.notexist", comment: "")
        alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
        alert.runModal()
    }
}
