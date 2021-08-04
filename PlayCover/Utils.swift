//
//  Utils.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import Foundation
import AppKit
import SwiftUI

extension String {
    func escape() -> String{
        return self.replacingOccurrences(of: " ", with: "\\ ").replacingOccurrences(of: "%20", with: "\\ ")
    }
}

func shell(_ command: String) -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.launchPath = "/bin/zsh"
    task.launch()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

func goToUrl(uri : String){
    let url = URL(string: uri)!
    NSWorkspace.shared.open(url)
}

func checkIfXcodeInstalled() -> Bool{
    return NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.dt.Xcode" ) != nil
}

func getDocs() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

func getApps() -> URL {
    return URL(fileURLWithPath: "/System/Applications/")
}

extension URL {
    func subDirectories() throws -> [URL] {
        // @available(macOS 10.11, iOS 9.0, *)
        guard hasDirectoryPath else { return [] }
        return try FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]).filter(\.hasDirectoryPath)
    }
}

extension NSOpenPanel {
    
    static func openApp(completion: @escaping (_ result: Result<URL, Error>) -> ()) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["ipa"]
        panel.canChooseFiles = true
        panel.begin { (result) in
            if result == .OK{
                let url = panel.urls.first
                completion(.success(url!))
            }
            else {
                print("shit!")
            }
        }
    }
}

func getExecutableNameFromPlist(url : URL) -> String? {
    return NSDictionary(contentsOfFile: url.path)!["CFBundleExecutable"] as! String?
}

func getIconNameFromPlist(url : URL) -> String? {
    if let plist = NSDictionary(contentsOfFile: url.path){
        do{
            var dict = (plist as NSDictionary).mutableCopy() as! NSMutableDictionary
            print(plist)
            dict["MinimumOSVersion"] = 1
            dict.write(toFile: url.path, atomically: true)
        } catch{
            print(error.localizedDescription)
        }
        if var icons = plist["CFBundleIconFiles"] as? Array<String>{
            return icons.last
        }
    }
    return nil
}

 func copyToClipBoard(textToCopy: String) {
    let pasteBoard = NSPasteboard.general
    pasteBoard.clearContents()
    pasteBoard.setString(textToCopy, forType: .string)

}
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

func bytesFromFile(filePath: String) -> [UInt8]? {

    guard let data = NSData(contentsOfFile: filePath) else { return nil }

    var buffer = [UInt8](repeating: 0, count: data.length)
    data.getBytes(&buffer, length: data.length)

    return buffer
}
