//
//  Utils.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation
import AppKit
import SwiftUI

extension URL {
    var esc : String {
        return self.path.esc
    }
}

extension String {
    var esc : String {
        return self.replacingOccurrences(of: " ", with: "\\ ")
    }
}

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

func goToUrl(uri : String){
    let url = URL(string: uri)!
    NSWorkspace.shared.open(url)
}

extension URL {
    func subDirectories() throws -> [URL] {
        // @available(macOS 10.11, iOS 9.0, *)
        guard hasDirectoryPath else { return [] }
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath)
    }
}

extension NSOpenPanel {
    
    static func openApp(completion: @escaping (_ result: Result<URL, Error>) -> ()) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["ipa"]
        panel.canChooseFiles = true
        panel.begin { (result) in
            if result == .OK{
                let url = panel.urls.first
                completion(.success(url!))
            }
            else {
                print("shit!")
            }
        }
    }
}

 func copyToClipBoard(textToCopy: String) {
    let pasteBoard = NSPasteboard.general
    pasteBoard.clearContents()
    pasteBoard.setString(textToCopy, forType: .string)

}

extension URL {
    var isDirectory: Bool {
       return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
}

func showInFinder(url: URL?) {
    guard let url = url else { return }
    
    if url.isDirectory {
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
    }
    else {
        showInFinderAndSelectLastComponent(of: url)
    }
}

fileprivate func showInFinderAndSelectLastComponent(of url: URL) {
    NSWorkspace.shared.activateFileViewerSelecting([url])
}

func bytesFromFile(filePath: String) -> [UInt8]? {

    guard let data = NSData(contentsOfFile: filePath) else { return nil }

    var buffer = [UInt8](repeating: 0, count: data.length)
    data.getBytes(&buffer, length: data.length)

    return buffer
}
