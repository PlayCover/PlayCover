//
//  Shell.swift
//  PlayCover
//

import Foundation
import Synchronization

/// Process helpers used by install / sign / launch paths.
///
/// The `async` overloads wait on `Process.terminationHandler` and are `@concurrent`, so callers on the
/// main actor suspend instead of blocking. The synchronous overloads remain for code that already runs
/// on a background thread inside a synchronous pipeline (unzip, plugin copy); never call them from the
/// main actor.
nonisolated enum Shell {
    // MARK: - Async

    @concurrent
    @discardableResult
    static func run(print: Bool = true, _ binary: String, _ args: String...) async throws -> String {
        try await run(print: print, binary, arguments: args)
    }

    @concurrent
    @discardableResult
    static func run(print: Bool = true, _ binary: String, arguments: [String],
                    environment: [String: String] = [:]) async throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = arguments
        if !environment.isEmpty {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
        }
        process.standardOutput = pipe
        process.standardError = pipe

        let (exits, exitContinuation) = AsyncStream.makeStream(of: Int32.self)
        process.terminationHandler = { finished in
            exitContinuation.yield(finished.terminationStatus)
            exitContinuation.finish()
        }

        try process.run()
        // Drain the pipe while the process runs; a full pipe buffer would otherwise stall it.
        async let output = readToEnd(pipe.fileHandleForReading)

        var status: Int32 = -1
        for await code in exits {
            status = code
        }
        let text = String(data: await output, encoding: .utf8) ?? "Shell error occured"
        if print {
            await Log.shared.log(text)
        }
        if status != 0 {
            throw text
        }
        return text
    }

    @concurrent
    static func signMacho(_ binary: URL) async throws {
        try await run("/usr/bin/codesign", "-fs-", binary.path)
    }

    @concurrent
    static func signAppWith(_ exec: URL, entitlements: URL) async throws {
        try await run("/usr/bin/codesign", "-fs-", exec.deletingLastPathComponent().path,
                      "--deep", "--entitlements", entitlements.path)
    }

    @concurrent
    static func signApp(_ exec: URL) async throws {
        try await run("/usr/bin/codesign", "-fs-", exec.deletingLastPathComponent().path,
                      "--deep", "--preserve-metadata=entitlements")
    }

    /// `codesign --verify --strict`; `false` when the seal does not verify.
    @concurrent
    static func verifySignature(_ bundle: URL) async -> Bool {
        do {
            try await run(print: false, "/usr/bin/codesign", "--verify", "--strict", bundle.path)
            return true
        } catch {
            return false
        }
    }

    @concurrent
    static func setMetalHUD(_ bundleID: String, enabled: Bool) async throws {
        try await run("/usr/bin/defaults", "write", bundleID, "MetalForceHudEnabled", "-bool", String(enabled))
    }

    @concurrent
    static func lldb(_ url: URL, withTerminalWindow: Bool = false) async throws {
        if withTerminalWindow {
            let command = "/usr/bin/lldb -o run \(url.esc) -o exit"
                .replacingOccurrences(of: "\\", with: "\\\\")
            let osascript = """
                tell app "Terminal"
                    reopen
                    activate
                    do script "\(command)"
                end tell
            """
            var possibleError: NSDictionary?
            NSAppleScript(source: osascript)?.executeAndReturnError(&possibleError)
            if let error = possibleError {
                for key in error.allKeys {
                    if let key = key as? String {
                        throw error.value(forKey: key).debugDescription
                    }
                }
            }
        } else {
            try await run("/usr/bin/lldb", "-o", "run", url.path, "-o", "exit")
        }
    }

    private static func readToEnd(_ handle: FileHandle) async -> Data {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                continuation.resume(returning: (try? handle.readToEnd()) ?? Data())
            }
        }
    }

    // MARK: - Synchronous (background pipelines only)

    @discardableResult
    static func run(print: Bool = true, _ binary: String, _ args: String...) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        let output = try pipe.fileHandleForReading.readToEnd() ?? Data()
        let text = String(data: output, encoding: .utf8) ?? "Shell error occured"
        if print {
            Task { @MainActor in
                Log.shared.log(text)
            }
        }

        process.waitUntilExit()
        let status = process.terminationStatus
        if status != 0 {
            throw text
        }
        return text
    }

    static func signMacho(_ binary: URL) throws {
        try run("/usr/bin/codesign", "-fs-", binary.path)
    }

    static func signApp(_ exec: URL) throws {
        try run("/usr/bin/codesign", "-fs-", exec.deletingLastPathComponent().path,
                "--deep", "--preserve-metadata=entitlements")
    }

    // MARK: - sudo

    @concurrent
    static func runSu(_ args: [String], _ argc: String) async -> Bool {
        let passwordWithNewline = argc + "\n"
        let sudo = Process()
        sudo.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        sudo.arguments = args
        let sudoIn = Pipe()
        let sudoOut = Pipe()
        sudo.standardOutput = sudoOut
        sudo.standardError = sudoOut
        sudo.standardInput = sudoIn

        let (exits, exitContinuation) = AsyncStream.makeStream(of: Void.self)
        sudo.terminationHandler = { _ in
            exitContinuation.yield()
            exitContinuation.finish()
        }

        do {
            try sudo.run()
        } catch {
            await Log.shared.error(error)
            return false
        }
        async let outputData = readToEnd(sudoOut.fileHandleForReading)

        if let data = passwordWithNewline.data(using: .utf8) {
            sudoIn.fileHandleForWriting.write(data)
            // Closing stdin right after the password avoids a hang on an incorrect password.
            try? sudoIn.fileHandleForWriting.close()
        }

        for await _ in exits {}
        let output = String(data: await outputData, encoding: .utf8) ?? ""
        if !output.isEmpty {
            await Log.shared.log(output)
        }
        return !output.contains("password")
    }
}

extension String: @retroactive Error {}

extension String: @retroactive LocalizedError {
    nonisolated public var errorDescription: String? { self }
}
