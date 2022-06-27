//
//  PlayApp.swift
//  PlayCover
//

import Foundation
import Cocoa

class PlayApp : PhysicialApp {
    
    init(appUrl : URL) {
        super.init(appUrl: appUrl, type: AppType.app)
    }
    
    override var searchText : String {
        return info.displayName.lowercased().appending(" ").appending(info.bundleName).lowercased()
    }
    
    func launch() {
        do {
            if prohibitedToPlay {
                container?.clear()
                throw PlayCoverError.appProhibited
            }
            
            AppsVM.shared.updatingApps = true
            AppsVM.shared.fetchApps()
            self.settings
            self.settings.sync()
            if try !Entitlements.areEntitlementsValid(app: self){
                sign()
            }
            if try !PlayTools.isInstalled(){
                Log.shared.msg("PlayTools are not installed! Please, move PlayCover.app into Applications!")
            } else if try !PlayTools.isValidArch(executable.path){
                Log.shared.msg("App had error during conversion.")
            } else if try !isCodesigned(){
                Log.shared.msg("App is not codesigned! Please, open Xcode and accept license agreement.")
            } else{
                URL(fileURLWithPath: url.path).openInFinder()
            }
            AppsVM.shared.updatingApps = false
        } catch {
            AppsVM.shared.updatingApps = false
            Log.shared.error(error)
        }
    }
    
    var icon : NSImage? {
        if let rep = NSWorkspace.shared.icon(forFile: url.path)
            .bestRepresentation(for: NSRect(x: 0, y: 0, width: 128, height: 128), context: nil, hints: nil) {
            let image = NSImage(size: rep.size)
            image.addRepresentation(rep)
            return image
        }
        return nil
    }
    
    var name : String {
        if info.displayName.isEmpty {
            return info.bundleName
        } else{
            return info.displayName
        }
    }
    
    lazy var settings : AppSettings = {
        AppSettings(info, container: container)
    }()
    
    var container : AppContainer?
    
    func isCodesigned() throws -> Bool {
        return try sh.shello(
            "/usr/bin/codesign",
            "-dv",
            executable.path
        ).contains("adhoc")
    }
    
    func showInFinder() {
        URL(fileURLWithPath: url.path).showInFinderAndSelectLastComponent()
    }
    
    func openAppCache(){
        container?.containerUrl.showInFinderAndSelectLastComponent()
    }
    
    func deleteApp() {
        do{
            try fm.delete(at: URL(fileURLWithPath: url.path))
            AppsVM.shared.fetchApps()
        } catch {
            Log.shared.error(error)
        }
    }
    
    func sign(){
        do {
            let tmpEnts = try TempAllocator.allocateTempDirectory().appendingPathComponent("entitlements.plist")
            let conf = try Entitlements.composeEntitlements(self)
            try conf.store(tmpEnts)
            sh.signAppWith(executable, entitlements: tmpEnts)
            TempAllocator.clearTemp()
        } catch{
            print(error)
            Log.shared.error(error)
        }
    }
    
}

extension PlayApp {
    
    var prohibitedToPlay : Bool {
        return PlayApp.PROHIBITED_APPS.contains(info.bundleIdentifier)
    }
    
    static let PROHIBITED_APPS = ["com.activision.callofduty.shooter", "com.garena.game.codm" , "com.tencent.tmgp.cod", "com.tencent.ig", "com.pubg.newstate", "com.tencent.tmgp.pubgmhd", "com.dts.freefireth", "com.dts.freefiremax"]
}
