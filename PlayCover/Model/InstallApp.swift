//
//  App.swift
//  PlayCover
//

import Foundation

import Darwin.sys
import AppKit

/// Represents an iOS-formatted .app bundle on the filesystem
public class InstallApp : PhysicialApp {
    
    /// All mach-o binaries within the app, including the executable itself. Call resolveValidMachOs to ensure a non-nil value.
    public private(set) var validMachOs: [URL]?
    
    /// Whether this app was created by unzipping from an IPA
    public var isTemporary: Bool {
        url.path.starts(with: TempAllocator.tempDirectory.path)
    }
    
    init(appUrl : URL) {
        super.init(appUrl: appUrl, type: AppType.install)
    }
    
    static func fromIPA (detectingAppNameInFolder folderURL: URL) throws -> InstallApp {
            let contents = try FileManager.default.contentsOfDirectory(atPath: folderURL.path)
            
            var url: URL?
            
            for entry in contents {
                guard entry.hasSuffix(".app") else {
                    continue
                }
                
                let entryURL = folderURL.appendingPathComponent(entry)
                var isDirectory: ObjCBool = false
                
                guard FileManager.default.fileExists(atPath: entryURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                    continue
                }
                
                url = entryURL
                break
            }
            
            guard let url = url else {
                throw PlayCoverError.infoPlistNotFound
            }
            
            return InstallApp(appUrl: url)
        }
}

// MARK: - Mach-O
private extension URL {
    // Wraps NSFileEnumerator since the geniuses at corelibs-foundation decided it should be completely untyped
    func enumerateContents(_ callback: (URL, URLResourceValues) throws -> ()) throws {
        guard let enumerator = FileManager.default.enumerator(at: self, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            do {
                try callback(fileURL, fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]))
            }
        }
    }
}

// You know, it'd be cool if Swift supported associated values. Unfortunately, fuck you.
public extension InstallApp {
    /// Returns an array of URLs to MachO files within the app
    func resolveValidMachOs() throws -> [URL] {
        if let validMachOs = validMachOs {
            return validMachOs
        }
        
        var resolved: [URL] = []
        
        try url.enumerateContents { url, attributes in
            guard attributes.isRegularFile == true, let fileSize = attributes.fileSize, fileSize > 4 else {
                return
            }
            
            if !url.pathExtension.isEmpty && url.pathExtension != "dylib" {
                return
            }
            
            let handle = try FileHandle(forReadingFrom: url)
            
            defer {
                try! handle.close()
            }
            
            guard let data = try handle.read(upToCount: 4) else {
                return
            }
            switch Array(data) {
            case [202, 254, 186, 190]: resolved.append(url)
            case [207, 250, 237, 254]: resolved.append(url)
            default: return
            }
        }
        
        validMachOs = resolved
        
        return resolved
    }
}

// MARK: - Signature
public extension InstallApp {
    /// Wrapper for codesign, applies the given entitlements to the application and all of its contents
    func saveEntitlements() throws {
        let toSave = try Entitlements.dumpEntitlements(exec: self.executable)
        try toSave.store(self.entitlements)
    }
    
    func removeMobileProvision() throws {
        let provision = url.appendingPathComponent("embedded.mobileprovision")
        if fm.fileExists(atPath: provision.path){
            try fm.removeItem(at: provision)
        }
    }
}

// MARK: - Wrapping
public extension InstallApp {
    /// Generates a wrapper bundle for an iOS app that allows it to be launched from Finder and other macOS UIs
    func wrap() throws -> URL {
        let location = PlayTools.playCoverContainer.appendingPathComponent(url.lastPathComponent)
        if FileManager.default.fileExists(atPath: location.path) {
            try FileManager.default.removeItem(at: location)
        }

        try FileManager.default.moveItem(at: url, to: location)
        return location
    }
}

public extension InstallApp {
    /// Regular codesign, does not accept entitlements. Used to re-seal an app after you've modified it.
    func fakesign(_ url: URL) throws {
        _ = try sh.shello("/usr/bin/codesign", "-fs-", url.path)
    }
}
