//
//  QueuesVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 2/13/23.
//

import Foundation
import DownloadManager

class QueuesVM {
    public static let shared = QueuesVM()

    private var installQueueItems: [(URL, Bool)] = [] // URL of ipa to install and if ipa should be deleted

    private var downloadQueueItems: [StoreAppData] = [] // App data of ipa to download

    private var currentInstallItem: (URL, Bool)?

    private var currentDownloadItem: StoreAppData?

    private func installItem() {
        if let item = currentInstallItem {
            Installer.install(ipaUrl: item.0, export: false, returnCompletion: { _ in
                Task { @MainActor in
                    // Remove ipa if it is specificed to be removed
                    if item.1 {
                        FileManager.default.delete(at: item.0)
                    }

                    self.installQueueItems.removeAll(where: { $0 == item }) // Remove item from queue

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
            DownloadApp(url: url, app: item, completion: {
                self.downloadQueueItems.removeAll(where: { $0 == item }) // Remove item from queue

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
        guard installQueueItems.firstIndex(where: { $0.0 == ipa }) == nil else {
            alreadyInQueueAlert()
            return false
        }

        installQueueItems.append((ipa, deleteIpa)) // Add item to queue

        guard currentInstallItem == nil else { // Ensure there is currently not an install in progress
            // Only show toast if there is already an item in queue
            ToastVM.shared.showToast(toastType: .notice,
                                     toastDetails: NSLocalizedString("queue.toast.installAdded", comment: ""))

            return true // Item has still been appened to queue successfully
        }

        currentInstallItem = installQueueItems.first // Set current install item to added item

        installItem() // Start consuming the queue

        return true
    }

    @discardableResult
    public func addDownloadItem(app: StoreAppData) -> Bool {
        // Make sure item is not already in queue
        guard downloadQueueItems.firstIndex(where: { $0 == app }) == nil else {
            alreadyInQueueAlert()
            return false
        }

        downloadQueueItems.append(app) // Add item to queue

        guard currentDownloadItem == nil else { // Ensure there is currently not a download in progress
            // Only show toast if there is already an item in queue
            ToastVM.shared.showToast(toastType: .notice,
                                     toastDetails: String(format: NSLocalizedString("queue.toast.downloadAdded",
                                                                                    comment: ""),
                                                          arguments: [app.name]))

            return true // Item has still been appened to queue successfully
        }

        currentDownloadItem = downloadQueueItems.first // Set current download item to added item

        downloadItem() // Start consuming queue

        return true
    }

    @discardableResult
    public func removeInstallItem(ipa: URL) -> Bool {
        // Make sure the item to remove is not currently being installed
        // Currently can't stop an install in progress
        // Also ensures that the item exists in the array
        if let currentInstallItem = currentInstallItem, currentInstallItem.0 != ipa,
            let idx = installQueueItems.firstIndex(where: { $0.0 == ipa }) {
            installQueueItems.remove(at: idx)

            return true
        } else {
            notInQueueAlert()
            return false
        }
    }

    @discardableResult
    public func removeDownloadItem(app: StoreAppData) -> Bool {
        if let idx = downloadQueueItems.firstIndex(of: app) { // Ensures the item is in the queue
            downloadQueueItems.remove(at: idx) // Remove item from queue

            if currentDownloadItem == app { // Checks if the item is currently being downloaded
                if let url = URL(string: app.link) { // Makes sure that the url exists
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
                }
            }

            return true
        } else {
            notInQueueAlert()
            return false
        }
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
