import SwiftUI
import Cocoa

struct AppInstallView: View {
    
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
                    pathToApp.showInFinder()
                } else{
                    logger.logs.append("Failure!")
                    installData.errorMessage = error
                    showInstallErrorAlert = true
                }
            }
        })
    }
    
    private func selectFile() {
        NSOpenPanel.selectIPA { (result) in
            if case let .success(url) = result {
                insertApp(url: url)
            }
        }
    }
    
    var body: some View {
            VStack{
                Text("Play Cover v0.6.0")
                    .fontWeight(.bold)
                    .font(.system(.largeTitle, design: .rounded)).padding().frame(minHeight: 150)
                VStack {
                    if !isLoading {
                        ZStack {
                            Text("Drag .ipa file here")
                                .fontWeight(.bold)
                                .font(.system(.title, design: .rounded)).padding().background( Rectangle().frame(minWidth: 600.0, minHeight: 150.0).foregroundColor(Color(NSColor.gridColor))
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
                        InstallSettings().environmentObject(installData)
                        Spacer()
                        Button("Add new app"){
                            selectFile()
                        }.alert(isPresented: $showWrongfileTypeAlert) {
                            Alert(title: Text("Wrong file type"), message: Text("You should use .ipa file"), dismissButton: .default(Text("OK")))
                        }.alert(isPresented: $showInstallErrorAlert ) {
                            Alert(title: Text("Error during installation!"), message: Text(installData.errorMessage), dismissButton: .default(Text("OK")))
                        }
                        Button("Download app"){
                            
                        }
                        Spacer().frame(minHeight: 20)
                    } else{
                        ProgressView("Installing...")
                    }
                   
                }
                Spacer(minLength: 20)
                LogView()
                    .environmentObject(InstalViewModel.shared)
                    .environmentObject(Logger.shared)
            }.padding().frame(minWidth: 700)
    }
}

struct LogView : View {
    @EnvironmentObject var userData: InstalViewModel
    @EnvironmentObject var logger: Logger
    var body: some View {
        VStack{
            if !logger.logs.isEmpty {
                Button("Copy log"){
                    logger.logs.copyToClipBoard()
                }
            }
            ScrollView {
                VStack(alignment: .leading) {
                    Text(logger.logs).padding().lineLimit(nil).frame(alignment: .leading)
                }
            }.frame(maxHeight: 200).padding()
        }.padding()
    }
}

struct InstallSettings : View {
    @EnvironmentObject var installData: InstalViewModel
    
    var body: some View {
            ZStack(alignment: .leading){
                Rectangle().frame(width: 320.0, height: 100.0).foregroundColor(Color(NSColor.windowBackgroundColor))
                                .cornerRadius(16).padding()
                VStack(alignment: .leading){
                    Toggle("Fullscreen & Keymapping", isOn: $installData.makeFullscreen).frame(alignment: .leading)
                    Toggle("Alternative convert method", isOn: $installData.useAlternativeWay).frame(alignment: .leading)
                    Toggle("Fix login in games", isOn: $installData.fixLogin).frame(alignment: .leading)
                    Toggle("Export for iOS, Mac (Sideloadly, AltStore)", isOn: $installData.exportForSideloadly).frame(alignment: .leading)
                }.padding(.init(top: 0, leading: 20, bottom: 0, trailing: 0))
            }
    }
}


