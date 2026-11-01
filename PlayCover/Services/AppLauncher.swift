//
//  AppLauncher.swift
//  PlayCover
//

import AppKit
import IOKit.pwr_mgt
import Synchronization

/// Runs one launch of an installed app: policy checks, re-sealing, KeyCover, `NSWorkspace` launch, and
/// the session that follows (display sleep assertion while frontmost, re-locking KeyCover after quit).
@MainActor
final class AppLauncher {
    static let launchConfirmationTimeout: Duration = .seconds(45)

    /// Common Metal and capture related environment keys that must not leak into the child process.
    private static let metalEnvKeys: [String] = [
        "METAL_DEVICE_WRAPPER_TYPE",
        "METAL_DEBUG_LAYER",
        "MTL_DEBUG_LAYER",
        "METAL_API_VALIDATION",
        "METAL_SHADER_VALIDATION",
        "METAL_SHADER_VALIDATION_OPTIONS",
        "METAL_CAPTURE_ENABLED",
        "METAL_CAPTURE_OUTPUT_FILE",
        "METAL_CAPTURE_TYPE",
        "METAL_FORCE_LAZY_COMPILATION",
        "METAL_FRAME_CAPTURE_ENABLED",
        "METAL_ERROR_MODE",
        "MTLCaptureEnabled"
    ]

    private let app: PlayApp
    private let keyCover: KeyCoverService
    private var displaySleepAssertionID: IOPMAssertionID?

    init(app: PlayApp, keyCover: KeyCoverService = .shared) {
        self.app = app
        self.keyCover = keyCover
    }

    func launch() async {
        do {
            app.isStarting = true
            defer { app.isStarting = false }

            if app.prohibitedToPlay {
                await app.clearAllCache()
                throw PlayCoverError.appProhibited
            } else if app.maliciousProhibited {
                await app.clearAllCache()
                app.deleteApp()
                throw PlayCoverError.appMaliciousProhibited
            }

            if await VersionCheck.shared.checkNewVersion(myApp: app) { return }

            app.settings.sync()
            try await AppSigner.applyFullScreenDeclaration(app)
            try await AppSigner.sealIfNeeded(app)

            // Wait for keychain unlock to finish before continuing
            await keyCover.unlock(for: app)

            if try !PlayTools.isInstalled() {
                Log.shared.error("PlayTools are not installed! Please move PlayCover.app into Applications!")
            } else if try !Macho.isMachoValidArch(app.executable) {
                Log.shared.error("The app threw an error during conversion.")
            } else {
                Self.clearDebugAffectingEnvironment()

                if app.settings.openWithLLDB {
                    let executable = app.executable
                    let withTerminal = app.settings.openLLDBWithTerminal
                    Task {
                        do {
                            try await Shell.lldb(executable, withTerminalWindow: withTerminal)
                        } catch {
                            Log.shared.error(error)
                        }
                    }
                } else {
                    // Keep the Finder shortcut pointed at the bundle that was just sealed.
                    // Launch the real bundle itself; the shortcut is not a signed bundle.
                    app.removeAlias()
                    app.createAlias()

                    try await runAppExec()
                }
            }
        } catch {
            Log.shared.error(error)
        }
    }

    /// Clears environment variables that can force debug wrappers or validation layers.
    static func clearDebugAffectingEnvironment() {
        for (key, _) in ProcessInfo.processInfo.environment where key.hasPrefix("DYLD_") {
            unsetenv(key)
        }
        for key in metalEnvKeys {
            unsetenv(key)
        }
    }

    private func runAppExec() async throws {
        let config = NSWorkspace.OpenConfiguration()
        let gate = OnceResume()
        let url = app.url

        let runningApp: NSRunningApplication = try await withCheckedThrowingContinuation { continuation in
            NSWorkspace.shared.openApplication(at: url, configuration: config) { runningApp, error in
                if let error {
                    gate.finish(continuation, with: .failure(error))
                } else if let runningApp {
                    gate.finish(continuation, with: .success(runningApp))
                } else {
                    gate.finish(continuation, with: .failure(PlayCoverError.launchTimedOut))
                }
            }
            Task {
                try? await Task.sleep(for: Self.launchConfirmationTimeout)
                gate.finish(continuation, with: .failure(PlayCoverError.launchTimedOut))
            }
        }

        Task { await watchSession(runningApp) }
    }

    /// Follows the launched process through `NSWorkspace` notifications until it quits.
    private func watchSession(_ runningApp: NSRunningApplication) async {
        let pid = runningApp.processIdentifier

        // Subscribe to all three before reading the current state, or a change in between is lost.
        let terminations = Self.processIdentifiers(of: NSWorkspace.didTerminateApplicationNotification)
        let activationEvents = Self.processIdentifiers(of: NSWorkspace.didActivateApplicationNotification)
        let deactivationEvents = Self.processIdentifiers(of: NSWorkspace.didDeactivateApplicationNotification)
        let activations = Task { [weak self] in
            for await activated in activationEvents where activated == pid {
                self?.disableDisplaySleep()
            }
        }
        let deactivations = Task { [weak self] in
            for await deactivated in deactivationEvents where deactivated == pid {
                self?.enableDisplaySleep()
            }
        }

        if runningApp.isActive {
            disableDisplaySleep()
        }
        if !runningApp.isTerminated {
            for await terminated in terminations where terminated == pid {
                break
            }
        }
        activations.cancel()
        deactivations.cancel()

        enableDisplaySleep()
        // The quitting app may still be flushing its key database.
        try? await Task.sleep(for: .seconds(1))
        await keyCover.lock(for: app)
    }

    /// Process identifiers carried by a workspace notification, as they arrive.
    private static func processIdentifiers(of name: Notification.Name) -> AsyncStream<pid_t> {
        AsyncStream { continuation in
            let center = NSWorkspace.shared.notificationCenter
            // NotificationCenter observer tokens are safe to remove from any thread.
            nonisolated(unsafe) let token = center.addObserver(forName: name, object: nil, queue: nil) { notification in
                if let pid = processIdentifier(of: notification) {
                    continuation.yield(pid)
                }
            }
            continuation.onTermination = { _ in
                center.removeObserver(token)
            }
        }
    }

    nonisolated private static func processIdentifier(of notification: Notification) -> pid_t? {
        (notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication)?.processIdentifier
    }

    private func disableDisplaySleep() {
        guard displaySleepAssertionID == nil else { return }

        let reason = "PlayCover: \(app.info.bundleIdentifier) is disabling sleep" as CFString
        var assertionID: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result == kIOReturnSuccess {
            displaySleepAssertionID = assertionID
        }
    }

    private func enableDisplaySleep() {
        if let assertionID = displaySleepAssertionID {
            IOPMAssertionRelease(assertionID)
            displaySleepAssertionID = nil
        }
    }
}

/// Resumes a continuation at most once. LaunchServices can answer late, after the timeout.
nonisolated final class OnceResume: Sendable {
    private let resumed = Mutex(false)

    func finish<Value>(_ continuation: CheckedContinuation<Value, Error>, with result: sending Result<Value, Error>) {
        let isFirst = resumed.withLock { resumed in
            defer { resumed = true }
            return !resumed
        }
        if isFirst {
            continuation.resume(with: result)
        }
    }
}
