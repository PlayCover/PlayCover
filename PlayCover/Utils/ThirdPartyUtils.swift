//
//  ThirdPartyUtils.swift
//  PlayCover
//

import Foundation

let utils = ThirdPartyUtils.self

class ThirdPartyUtils {
    
    static var optool: URL = {
        return ThirdPartyUtils.bundleUtil("optool")
    }()
    
    static var ipatool : URL = {
        return ThirdPartyUtils.bundleUtil("ipatool")
    }()
    
    static var crypt : URL = {
        return ThirdPartyUtils.bundleUtil("appdecrypt")
    }()
    
    private static func bundleUtil(_ utilName : String) -> URL{
        do{
            if let util = Bundle.main.url(forResource: utilName, withExtension: ""){
                if !fm.isExecutableFile(atPath: util.path){
                    try util.fixExecutable()
                }
                return util
            }
            throw PlayCoverError.appInstalledNotProperly
        } catch{
            return URL.init(fileURLWithPath: "")
        }
    }
    
}

