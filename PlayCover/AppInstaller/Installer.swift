//
//  Installer.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 24.11.2021.
//

import Foundation

class Installer {
    
    static func install(ipaUrl : URL, returnCompletion: @escaping (URL?) -> ()){
        InstallVM.shared.next(.begin)
        DispatchQueue.global(qos: .background).async {
        do {
            let ipa = IPA(url: ipaUrl)
            InstallVM.shared.next(.unzip)
            let app = try ipa.unzip()
            InstallVM.shared.next(.library)
            try app.saveEntitlements()
            let machos = try app.resolveValidMachOs()
            
            InstallVM.shared.next(.playtools)
            try PlayTools.installFor(app.executable, resign: true)
            
            for macho in machos {
                if try PlayTools.isMachoEncrypted(atURL: macho) {
                    throw PlayCoverError.appEncrypted
                }
                try PlayTools.replaceLibraries(atURL: macho)
                try PlayTools.convertMacho(macho)
                _ = try app.fakesign(macho)
            }
            
            // -rwxr-xr-x
            try app.executable.setBinaryPosixPermissions(0o755)
            
            try app.removeMobileProvision()
            
            let info = app.info
            
            AnalyticsService.shared.logAppInstall(info.bundleIdentifier)
            info.assert(minimumVersion: 11.0)
            try info.write()
            
            InstallVM.shared.next(.wrapper)

            let installed = try app.wrap()
            PlayApp(appUrl: installed).sign()
            try ipa.releaseTempDir()
            InstallVM.shared.next(.finish)
            returnCompletion(installed)
        } catch {
            Log.shared.error(error)
            InstallVM.shared.next(.finish)
            returnCompletion(nil)
        }
    }
    }
    
    static func exportForSideloadly(ipaUrl : URL, returnCompletion: @escaping (URL?) -> ()) {
        InstallVM.shared.next(.begin)
        
        DispatchQueue.global(qos: .background).async {
        do {
            let ipa = IPA(url: ipaUrl)
            InstallVM.shared.next(.unzip)
            let app = try ipa.unzip()
            InstallVM.shared.next(.library)
            try app.saveEntitlements()
            let machos = try app.resolveValidMachOs()
            
            InstallVM.shared.next(.playtools)
            try PlayTools.injectFor(app.executable, payload: app.url)
            
            for macho in machos {
                if try PlayTools.isMachoEncrypted(atURL: macho) {
                    throw PlayCoverError.appEncrypted
                }
            }
            
            let info = app.info
            
            info.assert(minimumVersion: 11.0)
            try info.write()
            
            InstallVM.shared.next(.wrapper)

            let exported = try ipa.packIPABack(app: app.url)
            try ipa.releaseTempDir()
            InstallVM.shared.next(.finish)
            returnCompletion(exported)
        } catch {
            Log.shared.error(error)
            InstallVM.shared.next(.finish)
            returnCompletion(nil)
        }
    }
    }
    
}
