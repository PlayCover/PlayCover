//
//  FileExtensions.swift
//  PlayCover
//
//  Created by siri on 10.08.2021.
//

import Foundation

let fm = FileManager.default

extension FileManager{
    
    func delete(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            ulog("Clearing \(url.esc)\n")
            do {
                try FileManager.default.removeItem(atPath: url.path)
            } catch{
                
            }
        }
    }
    
    func clearCache(temp: URL){
        ulog("Clearing cache\n")
        do{
            try fm.delete(at: temp)
        } catch{
            
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
