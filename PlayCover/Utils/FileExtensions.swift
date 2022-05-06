//
//  FileExtensions.swift
//  PlayCover

import Foundation
import AppKit

let fm = FileManager.default

extension FileManager{
    
    func delete(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(atPath: url.path)
            } catch{
                Log.shared.error(error)
            }
        }
    }
    
    func copy(at srcURL: URL, to dstURL: URL) throws{
        if fm.fileExists(atPath: dstURL.path) {
            try fm.removeItem(at: dstURL)
        }
        try fm.copyItem(at: srcURL, to: dstURL)
    }
    
    func filesCount(inDir: URL) throws -> Int{
        if fm.fileExists(atPath: inDir.path){
            return try fm.contentsOfDirectory(atPath: inDir.path).count
        }
        return 0
    }
}

extension NSOpenPanel {
    
    static func selectIPA(completion: @escaping (_ result: Result<URL, Error>) -> ()) {
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
        }
    }
}
