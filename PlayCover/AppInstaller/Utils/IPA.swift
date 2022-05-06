//
//  IPA.swift
//  PlayCover
//

import Foundation

public class IPA {
    
    public let url: URL
    public private(set) var tempDir: URL?
    
    public init(url: URL) {
        self.url = url
    }
    
    public func allocateTempDir() throws -> URL {
        if let workDir = tempDir, FileManager.default.fileExists(atPath: workDir.path) {
            return workDir
        }
        
        let workDir = try TempAllocator.allocateTempDirectory()
        self.tempDir = workDir
        
        return workDir
    }
    
    public func releaseTempDir() throws {
        guard let workDir = tempDir else {
            return
        }
        
        if FileManager.default.fileExists(atPath: workDir.path) {
            try FileManager.default.removeItem(at: workDir)
        }
        
        self.tempDir = nil
    }
    
    public func unzip() throws -> InstallApp {
        let workDir = try allocateTempDir()
        
        switch unzip_to_destination(url.path, workDir.path) {
        case .success:
            return try InstallApp.fromIPA(detectingAppNameInFolder: workDir.appendingPathComponent("Payload"))
        case let bomError: throw PlayCoverError.appCorrupted
        }
    }
}
