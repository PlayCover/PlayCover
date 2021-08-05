import SwiftUI
import Cocoa

class UserData: ObservableObject {
    @Published var log : String = ""
    @Published var makeFullscreen : Bool = false
}

struct AppLibraryView: View {
    
    @EnvironmentObject var userData: UserData
    @State var isLoading : Bool = false
    
    private func insertApp(url : URL){
        isLoading = true
        AppCreator.handleApp(url : url, userData: userData, returnCompletion: { (data) in
            DispatchQueue.main.async {
                isLoading = false
                if let pathToApp = data {
                    userData.log.append("Success!")
                    showInFinder(url: pathToApp)
                } else{
                    userData.log.append("Failure!")
                }
            }
        })
    }
    
    private func selectFile() {
        NSOpenPanel.openApp { (result) in
            if case let .success(url) = result {
                insertApp(url: url)
            }
        }
    }
    
    var body: some View {
        
        NavigationView {
            VStack{
                Text("Play Cover")
                    .fontWeight(.bold)
                    .font(.system(.largeTitle, design: .rounded)).padding()
                Spacer().frame(height: 100)
                VStack {
                    if !isLoading {
                        ZStack {
                            Text("Drag .ipa file here. Note, that .ipa must be decrypted. You can find one on AppDb.")
                                .fontWeight(.bold)
                                .font(.system(.callout, design: .rounded)).padding().background( Rectangle().frame(width: 600.0, height: 150.0)
                                                .foregroundColor(.gray)
                                                .cornerRadius(16)
                                                .shadow(radius: 4).padding()).padding()
                        }.frame(minWidth: 600).padding().onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
                      
                            if let item = items.first {
                                if let identifier = item.registeredTypeIdentifiers.first {
                                    if identifier == "public.url" || identifier == "public.file-url" {
                                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                                            DispatchQueue.main.async {
                                                if let urlData = urlData as? Data {
                                                    let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                                    insertApp(url: urll)
                                                }
                                            }
                                        }
                                    }
                                }
                                return true
                            } else {
                                return false
                            }
                        }
                        Spacer()
                        Toggle("Make Fullscreen & add keymapping", isOn: $userData.makeFullscreen).padding()
                        Spacer()
                        Button("Add new app"){
                            selectFile()
                        }.padding()
                    } else{
                        ProgressView("Installing...")
                        
                    }
                   
                }
                LogView().environmentObject(userData)
            }
        }
    }
}

struct LogView : View {
    @EnvironmentObject var userData: UserData
    var body: some View {
        ScrollView {
            VStack {
                if !userData.log.isEmpty {
                    Button("Copy log"){
                        copyToClipBoard(textToCopy: userData.log)
                    }
                }
                Text(userData.log).background(Color(hex: 0x383838)).padding().lineLimit(nil)
            }.frame(minWidth: 900, minHeight: 200)
        }.frame(minWidth: 900,  minHeight: 200).padding()
    }
    
}



