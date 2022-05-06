//
//  StoreApp.swift
//  PlayCover
//

import Foundation
import AppKit


class StoreApp : BaseApp {
    
    let data : StoreAppData
    
    init(data : StoreAppData){
        self.data = data
        super.init(id: data.id, type: BaseApp.AppType.store)
    }
    
    override var searchText : String {
        return data.name.lowercased()
    }
    
    static var storeApps : [StoreApp] {
       var apps = [StoreApp]()
     
        do {
           for fragment in JSON.split(separator: "§"){
               let jsonData = fragment.data(using: .utf8)!
               let data: StoreAppData = try JSONDecoder().decode(StoreAppData.self, from: jsonData)
               apps.append(StoreApp(data: data))
            }
        } catch {
            Log.shared.error(error)
            Log.shared.msg("Unable to retrieve store!")
            Log.shared.log("Unable to retrieve store!", isError: true)
        }

       return apps
    }
    
    private static let JSON : String = {
        if let url = URL(string: "https://gist.githubusercontent.com/iVoider/53e9649d3abffc8a8b0187a37ac6b457/raw/") {
                    do {
                        let contents = try String(contentsOf: url)
                        return contents
                    } catch {
                        print(error)
                    }
                }
        return ""
    }()
    
     static let notice : String = {
        if let url = URL(string: "https://gist.githubusercontent.com/iVoider/2e654eb9590f3a2f493908a6179979fd/raw/") {
                    do {
                        let contents = try String(contentsOf: url)
                        return contents
                    } catch {
                        print(error)
                    }
                }
        return "To Genshin players: if you see <Data error, please login again> you need to enable SIP (csrutil enable). If you have problems with captcha login, press <Enable PlaySign> button below."
    }()
}

struct StoreAppData: Decodable {
    
    enum Region: String, Decodable {
        case Global, CN
    }

    var id: String
    let name: String
    let version: String
    let icon : String
    let link : String
    let region : Region
    
}
