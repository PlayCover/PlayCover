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

	static let isXcodeCliToolsInstalled: Bool = {
        let toolsPath = try? sh("xcode-select -p")
        if let toolsPath = toolsPath?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if FileManager.default.fileExists(atPath:
                toolsPath.appending("/usr/bin/notarytool")) { // This executable is gaurenteed
                                                              // to exist weather it's the CLT or the full xcode
                return true
            }
        }

		return false
	}()

    static func isMachoSigned(_ exec: URL) -> Bool {
        !shell("/usr/bin/codesign -dv \(exec.esc)").contains("code object is not signed at all")
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
            .moveItem(at: payload.appendingPathComponent(name).appendingPathExtension("ipa"), to: ipa)
    }

    static func signAppWith(_ exec: URL, entitlements: URL) {
        shell(
            "/usr/bin/codesign -fs- \(exec.deletingLastPathComponent().esc) --deep --entitlements \(entitlements.esc)")
    }

    static func signApp(_ exec: URL) {
        shell("/usr/bin/codesign -fs- \(exec.deletingLastPathComponent().esc) --deep --preserve-metadata=entitlements")
    }

    static func copyAppToTemp(_ bundleName: String, name: String, temp: URL) {
        shell("cp -R /Applications/\(bundleName.esc).app/Wrapper/\(name.esc).app \(temp.esc)/ipafile/Payload/")
    }
    static func removeTwitterSessionCookie () {
        let cookieURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Containers")
            .appendingPathComponent("com.miHoYo.GenshinImpact")
            .appendingPathComponent("Data")
            .appendingPathComponent("Library")
            .appendingPathComponent("Cookies")
            .appendingPathComponent("Cookies")
            .appendingPathExtension("binarycookies")
        shell("rm -rf \(cookieURL.path)")
    }

    static func sudosh(_ args: [String], _ argc: String) -> Bool {
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
        // Write the password
        sudoIn.fileHandleForWriting.write(passwordWithNewline.data(using: .utf8)!)

        // Close the file handle after writing the password; avoids a
        // hang for incorrect password.
        try? sudoIn.fileHandleForWriting.close()

        // Make sure we don't disappear while output is still being produced.
        sudo.waitUntilExit()
        return result
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
