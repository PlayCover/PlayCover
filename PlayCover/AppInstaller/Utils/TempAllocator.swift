//
//  SideloadIO.swift
//  PlayCover
//

import Foundation

internal class TempAllocator {
    
    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("PlayCover")
    }
    
    static func clearTemp(){
        do {
            try fm.delete(at: documentDirectory)
        } catch{
            Log.shared.error(error)
        }
    }
    
    static var tempDirectory: URL {
        documentDirectory.appendingPathComponent("tmp")
    }
    
    static func allocateTempDirectory() throws -> URL {
        let workDir = TempAllocator.tempDirectory.appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true, attributes: [:])
        
        return workDir
    }
}
