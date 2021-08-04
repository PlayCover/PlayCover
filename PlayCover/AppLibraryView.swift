import SwiftUI
import Cocoa

private let _imageCache = NSCache<AnyObject, AnyObject>()

class ImageLoader: ObservableObject {
    @Published var image: NSImage?
    @Published var isLoading = false
    
    var imageCache = _imageCache
    
    func loadImage(with url: URL) {
        let urlString = url.absoluteString
        if let imageFromCache = imageCache.object(forKey: urlString as AnyObject) as? NSImage {
            self.image = imageFromCache
            return
        }
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try Data(contentsOf: url)
                guard let image = NSImage(data:data) else {
                    return
                }
                self.imageCache.setObject(image, forKey: urlString as AnyObject)
                DispatchQueue.main.async { [weak self] in
                    self?.image = image
                }
                
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

class UserData: ObservableObject {
    @Published var filter : String = ""
    @Published var appList: [AppModel] = []
    @Published var log : String = ""
}

struct AppLibraryView: View {
    
    @State var filterText : String = ""
    @EnvironmentObject var userData: UserData
    @State var isLoading : Bool = false
    
    private func selectFile() {
        NSOpenPanel.openApp { (result) in
            if case let .success(url) = result {
                
                AppCreator.copyApp(url : url, returnCompletion: { (data) in
                    DispatchQueue.main.async {
                        userData.appList.append(data.app)
                        isLoading = false
                        userData.log = data.log
                    }
                })
            }
        }
    }
    
    var body: some View {
        
        let binding = Binding<String>(get: {
            self.filterText
        }, set: {
            self.filterText = $0
            userData.filter = self.filterText
        })
        
        NavigationView {
            VStack{
                Text("Apps Library")
                    .fontWeight(.bold)
                    .font(.system(.largeTitle, design: .rounded)).padding()
                VStack {
                    TextField("Search...", text: binding).padding().overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2).padding()
                    )
                    Filtered()
                    
                    if !isLoading {
                        ZStack {
                            
                            Rectangle().frame(width: 600.0, height: 150.0)
                                .foregroundColor(.gray)
                                .cornerRadius(16)
                                .shadow(radius: 4).padding()
                            Text("Drag .app file here")
                                .fontWeight(.bold)
                                .font(.system(.title, design: .rounded)).padding()
                        }.padding().onDrop(of: ["public.url","public.file-url"], isTargeted: nil) { (items) -> Bool in
                            isLoading = true
                            if let item = items.first {
                                if let identifier = item.registeredTypeIdentifiers.first {
                                    if identifier == "public.url" || identifier == "public.file-url" {
                                        item.loadItem(forTypeIdentifier: identifier, options: nil) { (urlData, error) in
                                            DispatchQueue.main.async {
                                                if let urlData = urlData as? Data {
                                                    let urll = NSURL(absoluteURLWithDataRepresentation: urlData, relativeTo: nil) as URL
                                                    AppCreator.copyApp(url : urll, returnCompletion: { (data) in
                                                        DispatchQueue.main.async {
                                                            userData.appList.append(data.app)
                                                            userData.log = data.log
                                                            isLoading = false
                                                        }
                                                    })
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
                        Button("Add new app"){
                            selectFile()
                            isLoading = true
                        }.padding()
                        ScrollView {
                            VStack {
                                if !userData.log.isEmpty {
                                    Button("Copy log"){
                                        copyToClipBoard(textToCopy: userData.log)
                                    }
                                }
                                Text(userData.log).background(Color(hex: 0x383838)).padding()
                            }.frame(maxWidth: .infinity)
                        }
                    } else{
                        ProgressView("Installing...")
                    }
                    
                }
                
            }
        }
    }
}

struct Filtered: View {
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        List(userData.appList.filter { $0.name.lowercased().starts(with: userData.filter.lowercased()) }) { app in
            NavigationLink(destination: AppDetail(app: app).environmentObject(DownloadManager())) {
                AppRow(app: app)
            }
        }
    }
}

struct AppRow: View {
    let app: AppModel
    @ObservedObject var imageLoader = ImageLoader()
    
    var body: some View {
        HStack{
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                if self.imageLoader.image != nil {
                    Image(nsImage: self.imageLoader.image!)
                        .resizable().frame(width: 48.0, height: 48.0)
                }
            }
            .frame(width: 48.0, height: 48.0)
            .aspectRatio(4/4, contentMode: .fit)
            .cornerRadius(8)
            .shadow(radius: 4)
        }.onAppear {
            let url = app.icon
            self.imageLoader.loadImage(with: url)
        }
        Text("\(String(app.name))")
    }
}

struct AppDetail: View {
    
    let app: AppModel
    @State var downloadProgress : Float = 0.0
    
    @EnvironmentObject var downloader : DownloadManager
    @EnvironmentObject var userData: UserData
    
    var body: some View {
        if !app.downloaded {
            if downloadProgress == 0.0{
                Button("Download (v.2.0.0)"){
                    downloader.downloadFile(url: app.id) { value in
                        DispatchQueue.main.async {
                            downloadProgress = value
                        }
                    }
                }
            } else if downloadProgress != -1{
                ProgressBar(value: $downloadProgress).frame(height: 4, alignment: .bottom).padding()
            } else{
                Text("Successfull!").onAppear{
                    let index = userData.appList.firstIndex { m in
                        m.id == app.id
                    }
                    var old = userData.appList[index!]
                    var new = AppModel(name: old.name, path: old.id, icon: old.icon, downloaded: true)
                    var newList = userData.appList
                    newList[index!] = new
                    userData.appList = newList
                }
            }
        } else{
            VStack{
                Spacer()
                Spacer()
                Button(action: {
                    NSWorkspace.shared.open(app.id)
                }) {
                    Text("         Play         ").font(.system(size: 30))
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue))
                }
                .buttonStyle(PlainButtonStyle()).frame(maxWidth: .infinity)
            }.padding()
        }
    }
}

struct ProgressBar: View {
    @Binding var value: Float
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(.blue)
                
                Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(.blue)
                    .animation(.linear)
            }.cornerRadius(45.0)
        }
    }
}



