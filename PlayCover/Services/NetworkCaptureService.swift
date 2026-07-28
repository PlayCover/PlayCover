//
//  NetworkCaptureService.swift
//  PlayCover
//

import AppKit
import Foundation

/// Routes a PlayCover app's traffic through a debugging proxy, the same way a phone is
/// pointed at one.
///
/// Apps launched by PlayCover are iOS apps running on macOS, so their networking goes
/// through CFNetwork, which takes its proxy configuration from the macOS network
/// settings rather than from the process environment. Capturing an app therefore means
/// pointing the system proxy at the chosen address for as long as the app runs. The
/// address may be on this Mac or on another machine, which also covers remote debugging.
final class NetworkCaptureService {
    static let shared = NetworkCaptureService()

    /// Where a previously applied proxy configuration is parked, so it can be put back
    /// even if PlayCover is killed while an app is being captured.
    static var backupURL: URL {
        PlayTools.playCoverContainer.appendingPathComponent("NetworkCaptureProxyBackup.plist")
    }

    private let lock = NSLock()

    /// Bundle identifiers of the apps currently being captured.
    private var capturingApps = Set<String>()

    private init() {}

    /// Opens a TCP connection to check that something is actually listening for us.
    /// The Network framework is unavailable here, as this target searches the private
    /// frameworks directory, where a different Network.framework shadows the public one.
    func isProxyReachable(host: String, port: Int, timeout: TimeInterval = 2) -> Bool {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var resolved: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(host, String(port), &hints, &resolved) == 0 else { return false }
        defer { freeaddrinfo(resolved) }

        var candidate = resolved
        while let address = candidate {
            if canConnect(to: address.pointee, timeout: timeout) { return true }
            candidate = address.pointee.ai_next
        }

        return false
    }

    private func canConnect(to address: addrinfo, timeout: TimeInterval) -> Bool {
        let descriptor = socket(address.ai_family, address.ai_socktype, address.ai_protocol)
        guard descriptor >= 0 else { return false }
        defer { close(descriptor) }

        // Connect without blocking, so a proxy that is not there cannot hold up a launch
        let flags = fcntl(descriptor, F_GETFL, 0)
        guard flags >= 0, fcntl(descriptor, F_SETFL, flags | O_NONBLOCK) >= 0 else { return false }

        if connect(descriptor, address.ai_addr, address.ai_addrlen) == 0 { return true }
        guard errno == EINPROGRESS else { return false }

        var pending = pollfd(fd: descriptor, events: Int16(POLLOUT), revents: 0)
        guard poll(&pending, 1, Int32(timeout * 1000)) == 1 else { return false }

        // A refused connection also wakes up poll, so ask the socket how it went
        var failure: Int32 = 0
        var length = socklen_t(MemoryLayout<Int32>.size)
        guard getsockopt(descriptor, SOL_SOCKET, SO_ERROR, &failure, &length) == 0 else { return false }

        return failure == 0
    }
}

// MARK: - Capture sessions

extension NetworkCaptureService {
    /// Starts routing traffic through the proxy for `app`. Returns whether a session was
    /// started, so the caller knows if it has to be ended later.
    @discardableResult
    func beginCapture(for app: PlayApp) -> Bool {
        let settings = app.settings.settings.networkCapture

        guard settings.enable, settings.isValid else { return false }

        if !isProxyReachable(host: settings.host, port: settings.port) {
            Log.shared.log("No proxy is listening on \(settings.host):\(settings.port), "
                           + "traffic of \(app.info.bundleIdentifier) will not be captured", isError: true)
            return false
        }

        lock.lock()
        capturingApps.insert(app.info.bundleIdentifier)
        lock.unlock()

        guard settings.setSystemProxy else { return true }

        // The first app to ask for the system proxy is the one that owns the backup,
        // which is not necessarily the first app being captured
        let hasBackup = FileManager.default.fileExists(atPath: NetworkCaptureService.backupURL.path)

        do {
            if !hasBackup {
                try backupSystemProxy()
            }
            try applySystemProxy(host: settings.host, port: settings.port, bypass: settings.bypassList)
        } catch {
            lock.lock()
            capturingApps.remove(app.info.bundleIdentifier)
            let isEmpty = capturingApps.isEmpty
            lock.unlock()

            // Only throw away a backup this call is responsible for, and only when
            // there is no other app left that would need it
            if !hasBackup && isEmpty {
                try? FileManager.default.removeItem(at: NetworkCaptureService.backupURL)
            }

            Log.shared.error(error)
            return false
        }

        return true
    }

    /// Ends `app`'s session, restoring the previous proxy configuration once the last
    /// captured app has quit.
    func endCapture(for app: PlayApp) {
        lock.lock()
        capturingApps.remove(app.info.bundleIdentifier)
        let isLastSession = capturingApps.isEmpty
        lock.unlock()

        guard isLastSession else { return }

        do {
            try restoreSystemProxy()
        } catch {
            Log.shared.error(error)
        }
    }

    /// Drops every session, e.g. when PlayCover itself is quitting.
    func endAllCaptures() {
        lock.lock()
        let wasCapturing = !capturingApps.isEmpty
        capturingApps.removeAll()
        lock.unlock()

        guard wasCapturing else { return }

        do {
            try restoreSystemProxy()
        } catch {
            Log.shared.error(error)
        }
    }

    /// Puts back a configuration left behind by a PlayCover that did not exit cleanly.
    /// Called on startup, before any app can have a session of its own.
    func restoreStaleSystemProxy() {
        guard FileManager.default.fileExists(atPath: NetworkCaptureService.backupURL.path) else { return }

        do {
            try restoreSystemProxy()
            Log.shared.log("Restored the network proxy settings left behind by a previous session")
        } catch {
            Log.shared.error(error)
        }
    }

    /// Adds a proxy tool's root certificate to the System keychain and marks it as a
    /// trusted root, so HTTPS decrypted by that proxy is accepted. Works with any tool's
    /// CA (Reqable, Proxyman, Charles, mitmproxy, …). Needs an administrator, so macOS
    /// puts up a password prompt. Must be called from the main thread.
    func trustCertificate(at certificate: URL) throws {
        try Shell.runAsAdmin("/usr/bin/security add-trusted-cert -d -r trustRoot "
                             + "-k /Library/Keychains/System.keychain \(certificate.esc)")
    }

    /// Variables for stacks that do their own networking instead of using CFNetwork.
    func proxyEnvironment(_ settings: NetworkCaptureSettings) -> [String: String] {
        let proxy = "http://\(settings.host):\(settings.port)"
        var environment = [
            "http_proxy": proxy,
            "HTTP_PROXY": proxy,
            "https_proxy": proxy,
            "HTTPS_PROXY": proxy,
            "all_proxy": proxy,
            "ALL_PROXY": proxy
        ]

        if !settings.bypassList.isEmpty {
            let bypass = settings.bypassList.joined(separator: ",")
            environment["no_proxy"] = bypass
            environment["NO_PROXY"] = bypass
        }

        return environment
    }
}

// MARK: - macOS proxy configuration

extension NetworkCaptureService {
    /// Stores the current configuration so it can be put back later.
    private func backupSystemProxy() throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        try encoder.encode(try SystemProxy.read()).write(to: NetworkCaptureService.backupURL, options: .atomic)
    }

    private func applySystemProxy(host: String, port: Int, bypass: [String]) throws {
        try SystemProxy.apply(host: host, port: port, bypass: bypass)
    }

    /// Puts the stored configuration back and forgets it. Does nothing when there is
    /// none, so it is safe to call more often than it is needed.
    private func restoreSystemProxy() throws {
        let backupURL = NetworkCaptureService.backupURL
        guard let data = try? Data(contentsOf: backupURL) else { return }

        let backup = try PropertyListDecoder().decode([SystemProxy.ServiceState].self, from: data)

        defer { try? FileManager.default.removeItem(at: backupURL) }
        try SystemProxy.restore(backup)
    }
}
