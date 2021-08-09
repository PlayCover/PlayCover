import SwiftUI
import Cocoa

struct AppLibraryView: View {
    
    @EnvironmentObject var installData: InstalViewModel
    @EnvironmentObject var logger: Logger
    @State var isLoading : Bool = false
    @State var showWrongfileTypeAlert : Bool = false
    @State var showInstallErrorAlert : Bool = false
    
    private func insertApp(url : URL){
        isLoading = true
        installData.errorMessage = ""
        logger.logs = ""
        AppInstaller.shared.installApp(url : url, returnCompletion: { (app, error) in
            DispatchQueue.main.async {
                isLoading = false
                if let pathToApp = app {
                    logger.logs.append("Success!")
                    showInFinder(url: pathToApp)
                } else{
                    logger.logs.append("Failure!")
                    installData.errorMessage = error
                    showInstallErrorAlert = true
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
                        }.padding()
                        Spacer()
                        Toggle("Make Fullscreen & add keymapping", isOn: $installData.makeFullscreen).padding()
                        Toggle("Alternative convert method", isOn: $installData.useAlternativeWay).padding()
                        Toggle("Fix login in games (Still Supporter only feature) ", isOn: $installData.fixLogin).padding().disabled(true)
                        Spacer()
                        Button("Add new app"){
                            selectFile()
                        }.padding().alert(isPresented: $showWrongfileTypeAlert) {
                            Alert(title: Text("Wrong file type"), message: Text("You should use .ipa file"), dismissButton: .default(Text("OK")))
                        }.padding().alert(isPresented: $showInstallErrorAlert ) {
                            Alert(title: Text("Error during installation!"), message: Text(installData.errorMessage), dismissButton: .default(Text("OK")))
                        }
                    } else{
                        ProgressView("Installing...")
                    }
                   
                }
                LogView()
                    .environmentObject(InstalViewModel.shared)
                    .environmentObject(Logger.shared)
            }
        }
    }
}

struct LogView : View {
    @EnvironmentObject var userData: InstalViewModel
    @EnvironmentObject var logger: Logger
    var body: some View {
        ScrollView {
            VStack {
                if !logger.logs.isEmpty {
                    Button("Copy log"){
                        copyToClipBoard(textToCopy: logger.logs)
                    }
                }
                Text(logger.logs).padding().lineLimit(nil)
            }.frame(minWidth: 900, minHeight: 200)
        }.frame(minWidth: 900,  minHeight: 200).padding()
    }
    
}


