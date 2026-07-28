//
//  Shell.swift
//  PlayCover
//

import Foundation

class Shell: ObservableObject {
    @discardableResult
    static func run(print: Bool = true, _ binary: String, _ args: String...) throws -> String {
        try run(print: print, binary, arguments: args)
    }

    @discardableResult
    static func run(print: Bool = true, _ binary: String, arguments: [String]) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        let output = try pipe.fileHandleForReading.readToEnd() ?? Data()
        if print {
            Log.shared.log(String(data: output, encoding: .utf8) ?? "Shell error occured")
        }

        process.waitUntilExit()
        let status = process.terminationStatus
        if status != 0 {
            throw String(data: output, encoding: .utf8) ?? "Shell error occured"
        }
        return String(data: output, encoding: .utf8) ?? "Shell error occured"
    }

    static func runSu(_ args: [String], _ argc: String) -> Bool {
        let password = argc
        let passwordWithNewline = password + "\n"
        let sudo = Process()
        sudo.launchPath = "/usr/bin/sudo"
        sudo.arguments = args
        let sudoIn = Pipe()
        let sudoOut = Pipe()
        sudo.standardOutput = sudoOut
        sudo.standardError = sudoOut
        sudo.standardInput = sudoIn
        sudo.launch()

        var result = true

        // Show the output as it is produced
        sudoOut.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.count == 0 { return }

            if let out = String(bytes: data, encoding: .utf8) {
                Log.shared.log(out)
                if out.contains("password") {
                    result = false
                }
            }
        }
        if let data = passwordWithNewline.data(using: .utf8) {
            // Write the password
            sudoIn.fileHandleForWriting.write(data)

            // Close the file handle after writing the password; avoids a
            // hang for incorrect password.
            try? sudoIn.fileHandleForWriting.close()
        }

        // Make sure we don't disappear while output is still being produced.
        sudo.waitUntilExit()
        return result
    }

    /// Runs a command as root, letting macOS ask the user for an administrator password.
    /// Must be called from the main thread, as it puts up a window.
    static func runAsAdmin(_ command: String) throws {
        let escaped = command
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        var possibleError: NSDictionary?
        NSAppleScript(source: "do shell script \"\(escaped)\" with administrator privileges")?
            .executeAndReturnError(&possibleError)

        if let error = possibleError {
            throw error[NSAppleScript.errorMessage] as? String ?? "Shell error occured"
        }
    }

    static func signMacho(_ binary: URL) throws {
        try run("/usr/bin/codesign", "-fs-", binary.path)
    }

    static func signAppWith(_ exec: URL, entitlements: URL) throws {
        try run("/usr/bin/codesign", "-fs-", exec.deletingLastPathComponent().path,
                "--deep", "--entitlements", entitlements.path)
    }

    static func signApp(_ exec: URL) throws {
        try run("/usr/bin/codesign", "-fs-", exec.deletingLastPathComponent().path,
                "--deep", "--preserve-metadata=entitlements")
    }

    static func setMetalHUD(_ bundleID: String, enabled: Bool) throws {
        try run("/usr/bin/defaults", "write", bundleID,
                      "MetalForceHudEnabled", "-bool", String(enabled))
    }

    static func lldb(_ url: URL, withTerminalWindow: Bool = false) throws {
        Task(priority: .utility) {
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
                let appleScript = NSAppleScript(source: osascript)
                var possibleError: NSDictionary?
                appleScript?.executeAndReturnError(&possibleError)

                if let error = possibleError {
                    for key in error.allKeys {
                        if let key = key as? String {
                            throw error.value(forKey: key).debugDescription
                        }
                    }
                }
            } else {
                try run("/usr/bin/lldb", "-o", "run", url.path, "-o", "exit")
            }
        }
    }
}

extension Swift.String: Swift.Error { }

extension Swift.String: Foundation.LocalizedError {
    public var errorDescription: String? { self }
}
