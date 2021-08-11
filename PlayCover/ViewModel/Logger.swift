//
//  Logger.swift
//  PlayCover
//

import Foundation

let ulog = Logger.shared.log

class Logger: ObservableObject {
    
    static let shared = Logger()
    
    @Published var logs : String = ""
    
    func log(_ msg: String = "Unknown error!"){
        DispatchQueue.main.async {
            self.logs.append(msg)
        }
    }
    
    required init() {}
}
