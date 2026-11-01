//
//  NetworkVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 09/10/2022.
//

import Foundation
import Network
import Synchronization

class NetworkVM {
    private static let pathMonitor = NetworkPathMonitor()

    static func isConnectedToNetwork() -> Bool {
        let result = pathMonitor.isSatisfied()

        if !result && !ToastVM.shared.toasts.contains(where: { $0.toastType == .network }) {
            ToastVM.shared.showToast(
                toastType: .network,
                toastDetails: NSLocalizedString("ipaLibrary.noNetworkConnection.toast", comment: "")
            )
        }

        return result
    }

    static func urlAccessible(url: URL,
                              popup: Bool = false,
                              completion: (@Sendable (URL?, Bool) -> Void)? = nil) -> (URL?, Bool) {
        guard isConnectedToNetwork() else {
            completion?(nil, false)
            return (nil, false)
        }

        let semaphore = DispatchSemaphore(value: 0)
        let validStatusCodes = [200, 301, 302, 303, 307, 308]

        let available = Mutex(false)
        let finalURL = Mutex<URL?>(nil)

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }
            if let error = error {
                let message = error.localizedDescription
                Task { @MainActor in
                    if popup {
                        Log.shared.error(error)
                    } else {
                        Log.shared.log(message, isError: true)
                    }
                }
            } else if let httpResponse = response as? HTTPURLResponse {
                if validStatusCodes.contains(httpResponse.statusCode) {
                    finalURL.withLock { $0 = httpResponse.url }
                    available.withLock { $0 = true }
                } else if popup {
                    let status = httpResponse.statusCode
                    Task { @MainActor in
                        Log.shared.error("Unable to download: \(status) " +
                                         "\(HTTPURLResponse.localizedString(forStatusCode: status))")
                    }
                }
            }

            let resultURL = finalURL.withLock { $0 }
            let resultAvailable = available.withLock { $0 }
            if let completion {
                Task { @MainActor in
                    completion(resultURL, resultAvailable)
                }
            }
        }.resume()

        if completion == nil {
            semaphore.wait()
        }

        return (finalURL.withLock { $0 }, available.withLock { $0 })
    }
}

/// Keeps the latest network path from a long-lived `NWPathMonitor` so callers can query it synchronously.
private final class NetworkPathMonitor: Sendable {
    private static let firstUpdateTimeout: DispatchTimeInterval = .seconds(2)

    private let monitor = NWPathMonitor()
    private let status = Mutex<NWPath.Status?>(nil)
    private let firstUpdate = DispatchSemaphore(value: 0)

    init() {
        monitor.pathUpdateHandler = { [self] path in
            let isFirstUpdate = status.withLock { current in
                defer { current = path.status }
                return current == nil
            }
            if isFirstUpdate {
                firstUpdate.signal()
            }
        }
        monitor.start(queue: DispatchQueue(label: "io.playcover.PlayCover.NetworkPathMonitor"))
    }

    func isSatisfied() -> Bool {
        if status.withLock({ $0 }) == nil,
           firstUpdate.wait(timeout: .now() + NetworkPathMonitor.firstUpdateTimeout) == .success {
            // Let any other caller blocked on the first update continue as well.
            firstUpdate.signal()
        }
        return status.withLock { $0 } == .satisfied
    }
}
