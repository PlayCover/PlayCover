//
//  Utils.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation
import AppKit
import SwiftUI

extension String {
    var esc : String {
        return self.replacingOccurrences(of: " ", with: "\\ ")
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
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath)
    }
    var esc : String {
        return self.path.esc
    }
    var isDirectory: Bool {
       return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    func showInFinder() {
        if self.isDirectory {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: self.path)
        }
        else {
            showInFinderAndSelectLastComponent(of: self)
        }
    }

    fileprivate func showInFinderAndSelectLastComponent(of url: URL) {
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    func bytesFromFile() -> [UInt8]? {

        guard let data = NSData(contentsOfFile: self.path) else { return nil }

        var buffer = [UInt8](repeating: 0, count: data.length)
        data.getBytes(&buffer, length: data.length)

        return buffer
    }
    
}
