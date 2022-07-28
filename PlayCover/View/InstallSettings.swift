import SwiftUI

struct InstallProgress: View {

    @EnvironmentObject var install: InstallVM

    var body: some View {
        VStack {
            Text(install.status).frame(width: 300, height: 15, alignment: .center)
            ProgressBar().frame(width: 300, height: 15, alignment: .center).environmentObject(InstallVM.shared)
        }
    }

}

struct ProgressBar: View {

    @EnvironmentObject var install: InstallVM

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle().frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(.accentColor)

                Rectangle().frame(width: min(CGFloat(install.progress)*geometry.size.width, geometry.size.width),
                                  height: geometry.size.height)
                    .foregroundColor(.accentColor)
                    .animation(.linear, value: install.progress)
            }.cornerRadius(45.0)
        }
    }
}
