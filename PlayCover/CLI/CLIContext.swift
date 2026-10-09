//
//  CLIContext.swift
//  PlayCover
//

import Foundation

/// Process-wide state for headless CLI mode.
enum CLIContext {
    static var isCLI = false
    static var playToolsOverride: Bool?
    static var appCategoryOverride: LSApplicationCategoryType?

    /// Runs `body`, then spins the main run loop (draining main-queue /
    /// MainActor work used throughout the GUI code paths) until `body`
    /// invokes the supplied completion handler.
    static func waitForCompletion(_ body: (@escaping () -> Void) -> Void) {
        let box = CompletionBox()
        body { box.markFinished() }
        while !box.isFinished {
            _ = RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }
    }
}

final class CompletionBox: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false

    var isFinished: Bool {
        lock.lock()
        defer { lock.unlock() }
        return finished
    }

    func markFinished() {
        lock.lock()
        finished = true
        lock.unlock()
    }
}

enum CLIExitCode: Int32 {
    case success = 0
    case generalError = 1
    case badArguments = 2
    case appNotFound = 3
    case verificationFailed = 4
    case cancelled = 5
}

enum CLIOut {
    static func line(_ text: String) {
        FileHandle.standardOutput.write(Data((text + "\n").utf8))
    }

    static func error(_ text: String) {
        FileHandle.standardError.write(Data(("Error: " + text + "\n").utf8))
    }

    static func json<T: Encodable>(_ value: T) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(value),
              let str = String(data: data, encoding: .utf8) else {
            error("Failed to encode JSON output")
            exit(CLIExitCode.generalError)
        }
        line(str)
    }

    static func exit(_ code: CLIExitCode) -> Never {
        Foundation.exit(code.rawValue)
    }
}

/// Real-time progress renderer for CLI mode.
/// - TTY: single line refreshed in place with a carriage return.
/// - Piped output: one line per 10% boundary and per step change.
final class CLIProgressRenderer {
    static let shared = CLIProgressRenderer()

    private let lock = NSLock()
    private let isTTY: Bool
    private var label = ""
    private var lastBoundary = -1
    private var lastRenderTime = Date.distantPast
    private var inPlaceLineActive = false

    private init() {
        isTTY = isatty(FileHandle.standardOutput.fileDescriptor) != 0
    }

    func step(_ rawStep: String) {
        lock.lock()
        defer { lock.unlock() }
        terminateLineIfNeeded()
        label = CLIProgressRenderer.friendlyName(for: rawStep)
        lastBoundary = -1
        CLIOut.line("==> \(label)")
    }

    func render(progress: Double) {
        lock.lock()
        defer { lock.unlock() }
        let percent = max(0, min(100, Int((progress * 100).rounded())))
        if isTTY {
            let now = Date()
            if now.timeIntervalSince(lastRenderTime) < 0.05 && percent < 100 { return }
            lastRenderTime = now
            let width = 30
            let filled = Int(Double(width) * Double(percent) / 100.0)
            let bar = String(repeating: "=", count: filled) + String(repeating: "-", count: width - filled)
            let text = "\r  \(label) [\(bar)] \(percent)%"
            FileHandle.standardOutput.write(Data(text.utf8))
            inPlaceLineActive = true
        } else {
            let boundary = percent / 10
            if boundary != lastBoundary {
                lastBoundary = boundary
                CLIOut.line("  \(label): \(percent)%")
            }
        }
    }

    /// Ensures the in-place progress line is ended before plain output follows.
    func terminateLineIfNeeded() {
        if inPlaceLineActive {
            FileHandle.standardOutput.write(Data("\n".utf8))
            inPlaceLineActive = false
        }
    }

    static func friendlyName(for raw: String) -> String {
        switch raw {
        case "playapp.install.unzip": return "Extracting IPA"
        case "playapp.install.createWrapper": return "Creating app wrapper"
        case "playapp.install.installPlayTools": return "Installing PlayTools"
        case "playapp.install.signing": return "Signing app"
        case "playapp.install.addToLib": return "Adding to library"
        case "playapp.install.copy": return "Preparing"
        case "playapp.download.downloading": return "Downloading"
        case "playapp.download.integrityCheck": return "Verifying checksum"
        case "playapp.progress.finished": return "Finished"
        case "playapp.progress.failed": return "Failed"
        case "playapp.progress.canceled": return "Canceled"
        default: return raw
        }
    }
}
