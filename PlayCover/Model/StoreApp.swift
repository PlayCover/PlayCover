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
			let jsonData = JSON.data(using: .utf8)!
			let data: [StoreAppData] = try JSONDecoder().decode([StoreAppData].self, from: jsonData)
			for elem in data {
				apps.append(StoreApp(data: elem))
			}
			//    for fragment in JSON.split(separator: "§"){
			//        let jsonData = fragment.data(using: .utf8)!
			//        let data: StoreAppData = try JSONDecoder().decode(StoreAppData.self, from: jsonData)
			//        apps.append(StoreApp(data: data))
			//     }
		} catch {
			Log.shared.error(error)
			Log.shared.msg("Unable to retrieve store!")
			Log.shared.log("Unable to retrieve store!", isError: true)
		}

		return apps
	}

	private static let JSON : String = {
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
	}()

	static let notice : String = {
		if let url = URL(string: "https://playcover.io/store/notice.txt") {
			do {
				if checkAvaliability(url: url) {
					let contents = try String(contentsOf: url)
					return contents
				}
			} catch {
				print(error)
			}
		}
		return "To Genshin players: if you see <Data error, please login again> you need to enable SIP (csrutil enable). If you have problems with captcha login, press <Enable PlaySign> button below."
	}()
}

func checkAvaliability(url : URL) -> Bool{
	var avaliable = true
	var request = URLRequest(url: url)
	request.httpMethod = "HEAD"
	URLSession(configuration: .default)
		.dataTask(with: request) { (_, response, error) -> Void in
			guard error == nil else {
				print("Error:", error ?? "")
				avaliable = false
				return
			}

			guard (response as? HTTPURLResponse)?
				.statusCode == 200 else {
				print("down")
				avaliable = false
				return
			}

		}
		.resume()
	return avaliable
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
