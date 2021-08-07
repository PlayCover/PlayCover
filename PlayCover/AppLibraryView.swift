import SwiftUI
import Cocoa

class UserData: ObservableObject {
    @Published var log : String = ""
    @Published var makeFullscreen : Bool = false
    @Published var fixLogin : Bool = false
}

struct AppLibraryView: View {
    
    @EnvironmentObject var userData: UserData
    @State var isLoading : Bool = false
    @State var showWrongfileTypeAlert : Bool = false
    
    private func insertApp(url : URL){
        isLoading = true
        userData.log = ""
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
                            Text("Drag .ipa file here")
                                .fontWeight(.bold)
                                .font(.system(.title, design: .rounded)).padding().background( Rectangle().frame(width: 600.0, height: 150.0).foregroundColor(Color(NSColor.gridColor))
                                                .cornerRadius(16)
                                                .shadow(radius: 1).padding()).padding()
                        }.frame(minWidth: 600).padding().onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
                      
                            if let item = items.first {
                                if let identifier = item.registeredTypeIdentifiers.first {
                                    if identifier == "public.url" || identifier == "public.file-url" {
                                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                                            DispatchQueue.main.async {
                                                if let urlData = urlData as? Data {
                                                    let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                                    if urll.pathExtension == "ipa"{
                                                        insertApp(url: urll)
                                                    } else{
                                                        showWrongfileTypeAlert = true
                                                    }
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
                        Toggle("Fix login in games", isOn: $userData.fixLogin).padding()
                        Spacer()
                        Button("Add new app"){
                            selectFile()
                        }.padding().alert(isPresented: $showWrongfileTypeAlert) {
                            Alert(title: Text("Wrong file type"), message: Text("You should use .ipa file"), dismissButton: .default(Text("OK")))
                        }
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
                Text(userData.log).padding().lineLimit(nil)
            }.frame(minWidth: 900, minHeight: 200)
        }.frame(minWidth: 900,  minHeight: 200).padding()
    }
    
}


