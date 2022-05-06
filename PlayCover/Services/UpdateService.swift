//
//  UpdateService.swift
//  PlayCover
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
                .range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

class UpdateService : ObservableObject {
    
    static let shared = UpdateService()
    
    static let baseUrl = "https://github.com/iVoider/PlayCover/releases/download/$/PlayCover.$.zip"
    
    @Published var updateLink : String = ""
    
     func checkUpdate() {
        if let url = URL(string: "https://github.com/iVoider/PlayCover/releases") {
            do {
                let contents = try String(contentsOf: url)
                if let index = contents.index(of: "/releases/tag/") {
                    let end = contents.index(index, offsetBy: 19)
                    let start = contents.index(index, offsetBy: 14)
                    let version = contents[start..<end]
                    if version.compare(Bundle.main.releaseVersionNumber! , options: .numeric) == .orderedDescending{
                        updateLink = UpdateService.baseUrl.replacingOccurrences(of: "$", with: version)
                    }
                }
            } catch{
                
            }
        }
    }
}
