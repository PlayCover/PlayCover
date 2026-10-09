//
//  DownloadCommands.swift
//  PlayCover
//

import Foundation
import ArgumentParser

struct DownloadCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "download",
        abstract: "Download an app from a source or direct URL"
    )

    @Argument(help: "Bundle ID or direct download URL")
    var target: String

    @Flag(name: .long, help: "Install after downloading")
    var install = false

    func run() throws {
        let vm = StoreVM.shared
        vm.resolveSources()
        CLIContext.waitForCompletion { done in
            Task {
                await StoreVM.shared.awaitResolveSources()
                done()
            }
        }

        var app: SourceAppsData?
        var url: URL?

        if target.hasPrefix("http://") || target.hasPrefix("https://") {
            url = URL(string: target)
        } else {
            app = vm.sourcesApps.first { $0.bundleID == target }
            url = app.flatMap { URL(string: $0.link) }
        }

        guard let url = url else {
            CLIOut.error("Could not resolve a download URL for \(target)")
            CLIOut.exit(.badArguments)
        }

        let downloader = DownloadApp(url: url, app: app, warning: nil)

        if install {
            CLIContext.waitForCompletion { done in
                Task { @MainActor in
                    downloader.start()
                    done()
                }
            }
            // Wait until install finishes or the pipeline fails.
            CLIContext.waitForCompletion { done in
                Task {
                    while true {
                        if InstallVM.shared.status == .finish { done(); return }
                        if InstallVM.shared.status == .failed { done(); return }
                        if DownloadVM.shared.status == .failed || DownloadVM.shared.status == .canceled {
                            done()
                            return
                        }
                        try? await Task.sleep(nanoseconds: 200_000_000)
                    }
                }
            }
            CLIOut.exit(InstallVM.shared.status == .finish ? .success : .generalError)
        } else {
            var downloadFinished = false
            var downloadError: Error?
            var resultFile: URL?

            CLIProgressRenderer.shared.step("playapp.download.downloading")
            downloader.downloadVM.storeAppData = app
            downloader.downloader.addDownload(url: url, destinationURL: FileManager.default.temporaryDirectory,
                onProgress: { progress in
                    CLIProgressRenderer.shared.render(progress: Double(progress))
                }, onCompletion: { error, fileURL in
                    downloadError = error
                    resultFile = fileURL
                    downloadFinished = true
                })

            while !downloadFinished {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
            }
            CLIProgressRenderer.shared.terminateLineIfNeeded()

            if let error = downloadError {
                CLIOut.error(error.localizedDescription)
                CLIOut.exit(.generalError)
            }
            guard let file = resultFile else {
                CLIOut.error("Download produced no file")
                CLIOut.exit(.generalError)
            }
            if let expected = app?.checksum, !expected.isEmpty, let actual = file.sha256, actual != expected {
                CLIOut.error("Checksum mismatch: expected \(expected), got \(actual)")
                CLIOut.exit(.verificationFailed)
            }

            let baseName = app.map { "\($0.name)-\($0.version)" } ?? file.deletingPathExtension().lastPathComponent
            let destination = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
                .appendingPathComponent(baseName).appendingPathExtension("ipa")
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: file, to: destination)
            } catch {
                CLIOut.error(error.localizedDescription)
                CLIOut.exit(.generalError)
            }
            CLIOut.line("Downloaded: \(destination.path)")
            CLIOut.exit(.success)
        }
    }
}
