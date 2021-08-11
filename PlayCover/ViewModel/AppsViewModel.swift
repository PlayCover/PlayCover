//
//  AppsViewModel.swift
//  PlayCover
//
//  Created by siri on 11.08.2021.
//

import Foundation

let avm = AppsViewModel.shared

class AppsViewModel: ObservableObject {
    
    static let shared = AppsViewModel()
    
    @Published var apps : [AppModel] = []
    
    func fetchAppsBy(_ request : String){
        apps = []
        let result = sh.fetchAppsBy(request)
        if let range: Range<String.Index> = result.range(of: "1. ") {
            let response = String(result[range.lowerBound...])
            let lines = response.split(whereSeparator: \.isNewline)
            for line in lines{
                let model = AppModel(id: package(String(line)), name: appName(String(line)), version: version(String(line)))
                apps.append(model)
            }
        }
    }
    
    private func appName(_ line : String) -> String {
       return regexBetween(line, pattern: ". (.*?):")
    }
    
    private func package(_ line : String) -> String {
       return regexBetween(line, pattern: ": (.*?) \\(")
    }
    
    private func version(_ line : String) -> String {
       return regexBetween(line, pattern: " \\((.*?)\\).")
    }
    
    private func regexBetween(_ line : String, pattern : String) -> String{
        let regex = try! NSRegularExpression(pattern:pattern, options: [])
        var results = [String]()

        regex.enumerateMatches(in: String(line), options: [], range: NSMakeRange(0, line.utf16.count)) { result, flags, stop in
            if let r = result?.range(at: 1), let range = Range(r, in: line) {
                results.append(String(line[range]))
            }
        }

        return results.joined(separator: " ")
    }
    
    required init() {}

}
