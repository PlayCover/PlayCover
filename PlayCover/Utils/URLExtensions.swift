//
//  Utils.swift
//  PlayCover
//

import AppKit
import Foundation
import SwiftUI

extension String {
    var esc: String {
        replacingOccurrences(of: " ", with: "\\ ")
    }

    func copyToClipBoard() {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.setString(self, forType: .string)
    }
}

extension URL {
    func subDirectories() throws -> [URL] {
        // @available(macOS 10.11, iOS 9.0, *)
        guard hasDirectoryPath else { return [] }
        return try FileManager.default
            .contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            .filter(\.hasDirectoryPath)
    }

    var esc: String {
        path.esc
    }

    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
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

    func bytesFromFile() -> [UInt8]? {
        guard let data = NSData(contentsOfFile: path) else { return nil }

        var buffer = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&buffer, length: data.length)

        return buffer
    }

    func fixExecutable() throws {
        var attributes = [FileAttributeKey: Any]()
        attributes[.posixPermissions] = 0o777
        try FileManager.default.setAttributes(attributes, ofItemAtPath: path)
    }

    // Wraps NSFileEnumerator since the geniuses at corelibs-foundation decided it should be completely untyped
    func enumerateContents(_ callback: (URL, URLResourceValues) throws -> Void) throws {
        guard let enumerator = FileManager.default.enumerator(
            at: self,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return
        }

        for case let fileURL as URL in enumerator {
            do {
                try callback(fileURL, fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]))
            }
        }
    }
}
