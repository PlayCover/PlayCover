//
//  NetworkCaptureSettings.swift
//  PlayCover
//

import Foundation

/// Per app configuration for capturing network traffic through a debugging proxy.
///
/// PlayCover apps use CFNetwork, which reads its proxy configuration from the system
/// network settings, so capturing works the same way as pointing a phone at a debugging
/// proxy: route the traffic through the proxy and trust its root certificate. The proxy
/// can run on this Mac or on another machine, which also covers remote debugging.
struct NetworkCaptureSettings: Codable, Equatable {
    static let defaultHost = "127.0.0.1"
    static let defaultPort = 8080

    /// Route this app's traffic through the proxy when it is launched.
    var enable = false

    /// Address the proxy is listening on. Loopback for a proxy on this Mac, or the LAN /
    /// remote address of the machine running it.
    var host = NetworkCaptureSettings.defaultHost

    /// Port of the proxy server.
    var port = NetworkCaptureSettings.defaultPort

    /// Point the macOS network proxy at the address above while the app is running, and
    /// put the previous settings back when it quits. This is what CFNetwork based apps
    /// follow.
    var setSystemProxy = true

    /// Also pass `http_proxy` style variables to the app. CFNetwork ignores these, but
    /// engines bundling their own networking stack (Unity, cURL, gRPC) tend to read them.
    var setEnvironmentVariables = true

    /// Comma separated hosts that should not be captured, e.g. `*.apple.com, localhost`.
    var bypassDomains = ""

    init() {}

    /// Decoded leniently so that settings written by an older PlayCover keep working.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enable = try container.decodeIfPresent(Bool.self, forKey: .enable) ?? false
        host = try container.decodeIfPresent(String.self, forKey: .host) ?? NetworkCaptureSettings.defaultHost
        port = try container.decodeIfPresent(Int.self, forKey: .port) ?? NetworkCaptureSettings.defaultPort
        setSystemProxy = try container.decodeIfPresent(Bool.self, forKey: .setSystemProxy) ?? true
        setEnvironmentVariables = try container.decodeIfPresent(Bool.self, forKey: .setEnvironmentVariables) ?? true
        bypassDomains = try container.decodeIfPresent(String.self, forKey: .bypassDomains) ?? ""
    }

    /// Hosts to exclude from capture, as separate entries.
    var bypassList: [String] {
        bypassDomains
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// `true` when the address the user typed can actually be dialled.
    var isValid: Bool {
        !host.trimmingCharacters(in: .whitespaces).isEmpty && (1...65535).contains(port)
    }
}
