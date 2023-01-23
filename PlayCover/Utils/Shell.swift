//
//  Shell.swift
//  PlayCover
//

import Foundation

let shell = Shell.self

class Shell: ObservableObject {
    static let shared = Shell()

    @discardableResult
    static func sh(_ command: String, print: Bool = true, pipeStdErr: Bool = true) throws -> String {
		let task = Process()
		let pipe = Pipe()
        let errPipe = Pipe()

		task.standardOutput = pipe
		if pipeStdErr { task.standardError = pipe } else {task.standardError = errPipe}
		task.executableURL = URL(fileURLWithPath: "/bin/zsh")
		task.arguments = ["-c", command]
		try task.run()

		let data = try pipe.fileHandleForReading.readToEnd() ?? Data()
		let output = String(data: data, encoding: .utf8)!

		if print {
			Log.shared.log(output)
		}

		task.waitUntilExit()

		let status = task.terminationStatus
		if status != 0 {
            if pipeStdErr {
                throw output
            } else {
                let errOutput: String
                do {
                    let errData = try errPipe.fileHandleForReading.readToEnd() ?? Data()
                    errOutput = String(data: errData, encoding: .utf8)!
                } catch {
                    errOutput = "Command '\(command)' failed to execute."
                }
                throw errOutput
            }
		}
		return output
	}

    @discardableResult
    internal static func shello(print: Bool = true, _ binary: String, _ args: String...) throws -> String {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: binary)
        process.arguments = args
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()

        let output = try pipe.fileHandleForReading.readToEnd() ?? Data()
        if print {
            Log.shared.log(String(decoding: output, as: UTF8.self))
        }

        process.waitUntilExit()
        let status = process.terminationStatus
        if status != 0 {
            throw String(decoding: output, as: UTF8.self)
        }
        return String(decoding: output, as: UTF8.self)
    }

    static func codesign(_ binary: URL) {
        shell("/usr/bin/codesign -fs- \(binary.esc)")
    }

    static func quietUnzip(_ zip: URL, toUrl: URL) -> String {
        return shell("unzip -oq \(zip.esc) -d \(toUrl.esc)")
    }

    static func unzip(_ zip: URL, toUrl: URL) {
        shell("unzip \(zip.esc) -d \(toUrl.esc)")
    }

    static func zip(ipa: URL, name: String, payload: URL) throws {
        shell("cd \(payload.esc) && zip -r \(name.esc).ipa Payload")
        try FileManager.default
            .moveItem(at: payload.appendingEscapedPathComponent(name).appendingPathExtension("ipa"), to: ipa)
    }

    static func signAppWith(_ exec: URL, entitlements: URL) {
        shell(
            "/usr/bin/codesign -fs- \(exec.deletingLastPathComponent().esc) --deep --entitlements \(entitlements.esc)")
    }

    static func signApp(_ exec: URL) {
        shell("/usr/bin/codesign -fs- \(exec.deletingLastPathComponent().esc) --deep --preserve-metadata=entitlements")
    }

    static func lldb(_ url: URL, withTerminalWindow: Bool = false) {
        Task(priority: .utility) {
            var command = "/usr/bin/lldb -o run \(url.esc) -o exit"

            if withTerminalWindow {
                command = command.replacingOccurrences(of: "\\", with: "\\\\")
                let osascript = """
                    tell app "Terminal"
                        reopen
                        activate
                        do script "\(command)"
                    end tell
                """
                shell("/usr/bin/osascript -e '\(osascript)'", print: true)
            } else {
                shell(command, print: true)
            }
        }
    }

    @discardableResult
    static func shell(_ command: String, print: Bool = false) -> String {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/zsh"
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        if print {
            Log.shared.log(output)
        }

        return output
    }
}

extension String: Error { }

extension String: LocalizedError {
    public var errorDescription: String? { self }
}
