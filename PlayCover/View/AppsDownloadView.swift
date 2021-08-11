import SwiftUI

struct AppsDownloadView : View {
    
    @EnvironmentObject var apps : AppsViewModel
    
    @State var search: String = ""
    
    var body: some View {
        let binding = Binding<String>(get: {
            self.search
        }, set: {
            self.search = $0
            apps.fetchAppsBy(search)
        })
        
        VStack{
            TextField("Search app",text: binding)
            NavigationView {
                List {
                    ForEach(apps.apps, id: \.id) { app in
                        NavigationLink(destination: Button("Download"){
                            
                        }) {
                            AppRow(app: app)
                        }
                    }
                }
            }
            Button("Download"){
                
            }
        }.frame(idealWidth: 600, minHeight: 800)
        
    }
}

struct AppRow: View {
    var app : AppModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(app.name)
            Text(app.version)
            Text(app.id)
        }.frame(minWidth: 200, alignment: .leading)
    }
}


