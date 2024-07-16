//
//  NetworkVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 09/10/2022.
//

import SystemConfiguration
import Foundation

class NetworkVM {
    static func isConnectedToNetwork() -> Bool {
        guard let flags = getFlags() else { return false }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let result = (isReachable && !needsConnection)

        if !result && !ToastVM.shared.toasts.contains(where: { $0.toastType == .network }) {
            ToastVM.shared.showToast(
                toastType: .network,
                toastDetails: NSLocalizedString("ipaLibrary.noNetworkConnection.toast", comment: "")
            )
        }

        return result
    }

    static func getFlags() -> SCNetworkReachabilityFlags? {
        guard let reachability = ipv4Reachability() ?? ipv6Reachability() else { return nil }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return nil
        }
        return flags
    }

    static func ipv4Reachability() -> SCNetworkReachability? {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        return withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
    }

    static func ipv6Reachability() -> SCNetworkReachability? {
        var zeroAddress = sockaddr_in6()
        zeroAddress.sin6_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin6_family = sa_family_t(AF_INET6)

        return withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
    }

    static func urlAccessible(url: URL,
                              popup: Bool = false,
                              completion: ((URL?, Bool) -> Void)? = nil) -> (URL?, Bool) {
        guard isConnectedToNetwork() else {
            completion?(nil, false)
            return (nil, false)
        }

        let semaphore = DispatchSemaphore(value: 0)
        let validStatusCodes = [200, 301, 302, 303, 307, 308]

        var available = false
        var finalURL: URL?

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        URLSession.shared.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }
            if let error = error {
                if popup {
                    Log.shared.error(error)
                } else {
                    Log.shared.log(error.localizedDescription, isError: true)
                }
            } else {
                if let httpResponse = response as? HTTPURLResponse {
                    if validStatusCodes.contains(httpResponse.statusCode) {
                        finalURL = httpResponse.url
                        available = true
                    } else if popup {
                        Log.shared.error("Unable to download: \(httpResponse.statusCode) " +
                                         "\(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
                    }
                }
            }

            completion?(finalURL, available)
        }.resume()

        if completion == nil {
            semaphore.wait()
        }

        return (finalURL, available)
    }
}
