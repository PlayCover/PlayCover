//
//  ViewModel.swift
//  PlayCover
//

import Foundation

class InstalViewModel: ObservableObject {
    
    static let shared = InstalViewModel()
    
    @Published var makeFullscreen : Bool = false
    @Published var fixLogin : Bool = false
    @Published var errorMessage : String = ""
    @Published var useAlternativeWay : Bool = false
    
    required init() {}

}

let ulog = Logger.shared.log
let vm = InstalViewModel.shared

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
