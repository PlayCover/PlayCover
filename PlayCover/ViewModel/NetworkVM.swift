//
//  NetworkVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 09/10/2022.
//

// import Network

// I wanted to use the Network API for this, but it's completely missing
// so shitty old API it is :D

/*class NetworkVM: ObservableObject {

    static let shared = NetworkVM()

    @Published var networkConnection = false

    private init() {
        configureNetworkMonitor()
    }

    func configureNetworkMonitor() {
        let monitor = NWPathMonitor()

        monitor.pathUpdateHandler = { path in
            if path.status != .satisfied {
                self.networkConnection = false
            } else {
                self.networkConnection = true
            }
        }

        monitor.start(queue: DispatchQueue.global(qos: .background))
    }
}
*/

import SystemConfiguration
import Foundation

class NetworkVM {
    static func isConnectedToNetwork() -> Bool {
        guard let flags = getFlags() else { return false }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let result = (isReachable && !needsConnection)

        if !result {
            let networkToastExists = ToastVM.shared.toasts.contains { $0.toastType == .network }
            if !networkToastExists {
                ToastVM.shared.showToast(toastType: .network, toastDetails: String("No internet connection!"))
            }
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
}
