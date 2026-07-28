//
//  SystemProxy.swift
//  PlayCover
//

import Foundation

/// Reads and writes the macOS network proxy configuration through `networksetup`.
///
/// This is the configuration CFNetwork follows, so it is what decides where the traffic
/// of an app launched by PlayCover ends up.
enum SystemProxy {
    private static let networksetup = "/usr/sbin/networksetup"

    /// One of the two proxies (HTTP or HTTPS) of a network service.
    private struct ProxyState {
        var enabled = false
        var server = ""
        var port = 0
    }

    /// The proxy configuration of a single network service.
    struct ServiceState: Codable {
        let service: String
        let webEnabled: Bool
        let webServer: String
        let webPort: Int
        let secureEnabled: Bool
        let secureServer: String
        let securePort: Int
        let bypassDomains: [String]
    }

    /// Every enabled network service. Disabled ones are prefixed with an asterisk and
    /// cannot carry a proxy configuration.
    static func networkServices() throws -> [String] {
        try Shell.run(print: false, networksetup, arguments: ["-listallnetworkservices"])
            .split(whereSeparator: \.isNewline)
            .dropFirst() // an explanatory line about the asterisk
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("*") }
    }

    /// The current configuration of every network service.
    static func read() throws -> [ServiceState] {
        try networkServices().map { service in
            let web = try read(service: service, secure: false)
            let secure = try read(service: service, secure: true)

            return ServiceState(service: service,
                                webEnabled: web.enabled,
                                webServer: web.server,
                                webPort: web.port,
                                secureEnabled: secure.enabled,
                                secureServer: secure.server,
                                securePort: secure.port,
                                bypassDomains: try readBypassDomains(service: service))
        }
    }

    /// Points every network service at the given proxy, for HTTP as well as HTTPS.
    static func apply(host: String, port: Int, bypass: [String]) throws {
        for service in try networkServices() {
            try Shell.run(print: false, networksetup,
                          arguments: ["-setwebproxy", service, host, String(port)])
            try Shell.run(print: false, networksetup,
                          arguments: ["-setsecurewebproxy", service, host, String(port)])
            try Shell.run(print: false, networksetup,
                          arguments: ["-setwebproxystate", service, "on"])
            try Shell.run(print: false, networksetup,
                          arguments: ["-setsecurewebproxystate", service, "on"])

            if !bypass.isEmpty {
                try Shell.run(print: false, networksetup,
                              arguments: ["-setproxybypassdomains", service] + bypass)
            }
        }
    }

    /// Writes previously read state back. Every service is attempted, so one that has
    /// gone away in the meantime cannot leave the others pointed at the proxy.
    static func restore(_ states: [ServiceState]) throws {
        var failure: Error?

        for state in states {
            do {
                try restore(state)
            } catch {
                failure = error
            }
        }

        if let failure = failure {
            throw failure
        }
    }

    private static func restore(_ state: ServiceState) throws {
        // Setting a server also switches the proxy on, so the state is set afterwards
        if !state.webServer.isEmpty {
            try Shell.run(print: false, networksetup,
                          arguments: ["-setwebproxy", state.service, state.webServer, String(state.webPort)])
        }
        try Shell.run(print: false, networksetup,
                      arguments: ["-setwebproxystate", state.service, state.webEnabled ? "on" : "off"])

        if !state.secureServer.isEmpty {
            try Shell.run(print: false, networksetup,
                          arguments: ["-setsecurewebproxy", state.service,
                                      state.secureServer, String(state.securePort)])
        }
        try Shell.run(print: false, networksetup,
                      arguments: ["-setsecurewebproxystate", state.service, state.secureEnabled ? "on" : "off"])

        // "Empty" is how networksetup is told to clear the list. Passing an empty
        // string instead leaves a blank entry behind
        try Shell.run(print: false, networksetup,
                      arguments: ["-setproxybypassdomains", state.service]
                                 + (state.bypassDomains.isEmpty ? ["Empty"] : state.bypassDomains))
    }

    /// Parses the `Enabled: / Server: / Port:` block printed by `networksetup`.
    private static func read(service: String, secure: Bool) throws -> ProxyState {
        let output = try Shell.run(print: false, networksetup,
                                   arguments: [secure ? "-getsecurewebproxy" : "-getwebproxy", service])

        var state = ProxyState()

        for line in output.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: ":", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard parts.count == 2 else { continue }

            switch parts[0] {
            case "Enabled": state.enabled = parts[1].caseInsensitiveCompare("Yes") == .orderedSame
            case "Server": state.server = parts[1]
            case "Port": state.port = Int(parts[1]) ?? 0
            default: break
            }
        }

        return state
    }

    private static func readBypassDomains(service: String) throws -> [String] {
        try Shell.run(print: false, networksetup, arguments: ["-getproxybypassdomains", service])
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            // With nothing set, networksetup prints a localized sentence rather than an
            // empty list. Hostnames never contain spaces, so that is enough to tell apart
            .filter { !$0.isEmpty && !$0.contains(" ") }
    }
}
