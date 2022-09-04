//
//  Store.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 06/08/2022.
//

import Foundation

class StoreVM: ObservableObject {

    static let shared = StoreVM()

    private init() {
        fetchApps()
    }

    @Published var apps: [StoreAppData] = []

    func fetchApps() {
        DispatchQueue.global(qos: .userInteractive).async {
            var result: [StoreAppData] = []
            do {
                let jsonData = StoreVM.getStoreJson().data(using: .utf8)!
                let data: [StoreAppData] = try JSONDecoder().decode([StoreAppData].self, from: jsonData)
                for elem in data {
                    result.append(elem)
                }
            } catch {
                Log.shared.error(error)
                Log.shared.msg("Unable to retrieve store!")
                Log.shared.log("Unable to retrieve store!", isError: true)
            }

            DispatchQueue.main.async {
                self.apps.removeAll()

                if !uif.searchText.isEmpty {
                    result = result.filter({ $0.name.lowercased().contains(uif.searchText.lowercased()) })
                }

                self.apps.append(contentsOf: result)
            }
        }
    }

    static func checkAvaliability(url: URL) -> Bool {
        var avaliable = true
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        URLSession(configuration: .default)
            .dataTask(with: request) { _, response, error in
                guard error == nil else {
                    print("Error:", error ?? "")
                    avaliable = false
                    return
                }

                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    print("down")
                    avaliable = false
                    return
                }
            }
            .resume()
        return avaliable
    }

    static func getStoreJson() -> String {
        if let url = URL(string: "https://playcover.io/store/store.json") {
            do {
                if checkAvaliability(url: url) {
                    let contents = try String(contentsOf: url)
                    return contents
                }
            } catch {
                print(error)
            }
        }
        return "[]"
    }
}

struct StoreAppData: Decodable {
    enum Region: String, Decodable {
        // swiftlint:disable identifier_name
        case Global, CN
    }

    var id: String
    let name: String
    let version: String
    let icon: String
    let link: String
    let region: Region
}
