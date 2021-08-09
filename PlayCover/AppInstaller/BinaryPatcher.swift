//
//  BinaryPatcher.swift
//  PlayCover
//
//  Created by siri on 10.08.2021.
//

import Foundation

class BinaryPatcher {
    
    static func patchApp(app : URL, alternativeWay : Bool) throws {
        ulog("Converting app\n")
        if let enumerator = fm.enumerator(at: app, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isRegularFileKey])
                    if fileAttributes.isRegularFile! {
                        if isMacho(fileUrl: fileURL){
                            try patchBinary(fileUrl: fileURL, useAlternative: alternativeWay)
                        }
                    }
                }
            }
        }
    }
    
    private static func isMacho(fileUrl : URL) -> Bool {
        if !fileUrl.pathExtension.isEmpty && fileUrl.pathExtension != "dylib" {
            return false
        }
        if let bts = bytesFromFile(filePath: fileUrl.path){
            if bts.count > 4{
                let header = bts[...3]
                if header.count == 4{
                    if(AppInstaller.possibleHeaders.contains(Array(header))){
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private static func patchBinary(fileUrl : URL, useAlternative : Bool) throws {
        ulog("Converting \(fileUrl.lastPathComponent)\n")
        
        if !fileUrl.lastPathComponent.contains("PlayCoverInject") && !fileUrl.lastPathComponent.contains("MacHelper"){
            
            if useAlternative {
                try internalWay()
            } else{
                vtoolWay()
            }
        }
       
        ulog(shell("codesign -fs- \(fileUrl.esc)"))
        
        func vtoolWay(){
            shell("vtool -arch arm64 -set-build-version maccatalyst 10.0 14.5 -replace -output \(fileUrl.esc) \(fileUrl.esc)")
        }
        
        func internalWay() throws {
            convert(fileUrl.path.esc)
            let newUrl = fileUrl.path.appending("_sim")
            try fm.delete(at: fileUrl)
            try fm.moveItem(atPath: newUrl, toPath: fileUrl.path)
        }
        
    }
    
}
