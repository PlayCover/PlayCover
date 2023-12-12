//
//  URLExtensions.swift
//  PlayCover
//

import AppKit
import Foundation
import CryptoKit
import SwiftUI

extension String {
    var esc: String {
        let esc = ["\\", "\"", "'", " ", "(", ")", "[", "]", "{", "}", "&", "|",
                   ";", "<", ">", "`", "$", "!", "*", "?", "#", "~", "="]
        var str = self
        for char in esc {
            str = str.replacingOccurrences(of: char, with: "\\" + char)
        }
        return str
    }

    func copyToClipBoard() {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(self, forType: .string)
    }
}

extension URL {
    var esc: String {
        path.esc
    }

    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var sha256: String? {
        do {
            return SHA256.hash(data: try Data(contentsOf: self))
                .map { String(format: "%02hhx", $0) }
                .joined()
        } catch {
            return nil
        }
    }

    func openInFinder() {
        do {
            if isDirectory {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
            } else {
                showInFinderAndSelectLastComponent()
            }
        }
    }

    func showInFinder() {
        if isDirectory {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
        } else {
            NSWorkspace.shared.activateFileViewerSelecting([self])
        }
    }

    func showInFinderAndSelectLastComponent() {
        NSWorkspace.shared.activateFileViewerSelecting([self])
    }

    func fixExecutable() throws {
        var attributes = [FileAttributeKey: Any]()
        attributes[.posixPermissions] = 0o777
        try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
    }

    // Wraps NSFileEnumerator since the geniuses at corelibs-foundation decided it should be completely untyped
    func enumerateContents(blocking: Bool = true,
                           includingPropertiesForKeys keys: [URLResourceKey]? = nil,
                           options: FileManager.DirectoryEnumerationOptions? = nil,
                           _ callback: @escaping(URL, URLResourceValues) throws -> Void) {
        guard let enumerator = FileManager.default.enumerator(
            at: self,
            includingPropertiesForKeys: keys ?? [.isRegularFileKey],
            options: options ?? [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return
        }

        let queue = OperationQueue()
        queue.name = "io.playcover.PlayCover.URLExtension"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 15

        for case let fileURL as URL in enumerator {
            queue.addOperation {
                do {
                    try callback(fileURL, fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]))
                } catch {
                    // Don't show error, as there could be many files within the folder
                    // that would fail the callback
                    print(error)
                }
            }
        }

        if blocking {
            queue.waitUntilAllOperationsAreFinished()
        }
    }

    func appendingEscapedPathComponent(_ pathComponent: String) -> URL {
        let esc = [("/", ":")]

        var newPathComponent = pathComponent

        for (find, replace) in esc {
            newPathComponent = newPathComponent.replacingOccurrences(of: find, with: replace)
        }

        return self.appendingPathComponent(newPathComponent)
    }

    func setBinaryPosixPermissions(_ permissions: Int) throws {
        try FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: path)
    }
}
