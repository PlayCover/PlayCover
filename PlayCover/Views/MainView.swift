//
//  MainView.swift
//  PlayCover
//

import SwiftUI

struct MainView: View {
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.controlActiveState) var controlActiveState

    @EnvironmentObject var apps: AppsVM
    @EnvironmentObject var store: StoreVM
    @EnvironmentObject var integrity: AppIntegrity

    @ObservedObject var keyCoverObserved = KeyCoverObservable.shared

    @Binding public var isSigningSetupShown: Bool

    @State private var selectedView: Int? = -1
    @State private var navWidth: CGFloat = 0
    @State private var viewWidth: CGFloat = 0
    @State private var collapsed: Bool = false
    @State private var showSourceFolders = true
    @State private var showAppFolders = true
    @State private var selectedBackgroundColor: Color = Color.accentColor
    @State private var selectedTextColor: Color = Color.black
    @State private var addFolderPresented = false
    @State var newFolder = ""
    @ObservedObject var foldersObject = AppFolder()
    @State private var selectedSymbol: String = "folder"

    @ObservedObject private var URLObserved = URLObservable.shared

    var body: some View {
        GeometryReader { viewGeom in
            NavigationView {
                GeometryReader { sidebarGeom in
                    List {
                        NavigationLink(tag: 1, selection: $selectedView) {
                            AppLibraryView(selectedBackgroundColor: $selectedBackgroundColor,
                                                                       selectedTextColor: $selectedTextColor)
                        } label: {
                            Label("sidebar.appLibrary", systemImage: "square.grid.2x2")
                            Button {
                                withAnimation {
                                    showAppFolders.toggle()
                                }
                            } label: {
                                Image(systemName: showAppFolders ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .contextMenu(menuItems: {
                                Button(NSLocalizedString("folder.button.add", comment: ""), action: {
                                    addFolderPresented.toggle()
                                })
                                .keyboardShortcut(.escape, modifiers: .command)
                            })
                        }
                        if showAppFolders {
                            ForEach(foldersObject.folders.indices, id: \.hashValue) { index in
                                NavigationLink(tag: foldersObject.folders[index].id.hashValue,
                                               selection: $selectedView) {
                                    AppFolderView(selectedBackgroundColor: $selectedBackgroundColor,
                                                  selectedTextColor: $selectedTextColor,
                                                  apps: $foldersObject.folders[index],
                                                  appsEdited: foldersObject.folders[index]
                                    )
                                } label: {
                                    Label(foldersObject.folders[index].name,
                                          systemImage: foldersObject.folders[index].icon)
                                        .font(.caption)
                                        .padding(.leading)
                                        .contextMenu(menuItems: {
                                            Button(NSLocalizedString("folder.button.remove", comment: ""), action: {
                                                foldersObject.folders.remove(at: index)
                                            })
                                        })

                                }
                            }
                        }
                        NavigationLink(tag: 2, selection: $selectedView) {
                            IPALibraryView(storeVM: store,
                                           selectedBackgroundColor: $selectedBackgroundColor,
                                           selectedTextColor: $selectedTextColor)
                            .environmentObject(store)
                        } label: {
                            HStack {
                                Label("sidebar.ipaLibrary", systemImage: "arrow.down.circle")
                                Button {
                                    withAnimation {
                                        showSourceFolders.toggle()
                                    }
                                } label: {
                                    Image(systemName: showSourceFolders ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        if showSourceFolders {
                            let enabledSources: [SourceJSON] = StoreVM.shared.getEnabledSources()
                            ForEach(enabledSources, id: \.hashValue) { source in
                                    NavigationLink(tag: source.hashValue, selection: $selectedView) {
                                    IPASourceView(storeVM: store,
                                                  selectedBackgroundColor: $selectedBackgroundColor,
                                                  selectedTextColor: $selectedTextColor,
                                                  sourceName: source.name,
                                                  sourceApps: source.data)
                                    .environmentObject(store)
                                } label: {
                                    Label(source.name, systemImage: "folder")
                                        .font(.caption)
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                    .frame(minWidth: 150)
                    .toolbar {
                        ToolbarItem { // Sits on the left by default
                            Button {
                                toggleSidebar()
                            } label: {
                                Image(systemName: "sidebar.leading")
                            }
                        }
                    }
                    .onChange(of: sidebarGeom.size) { newSize in
                        navWidth = newSize.width
                    }
                    .onChange(of: colorScheme) { scheme in
                        if scheme == .dark {
                            selectedTextColor = .white
                        } else {
                            if controlActiveState == .inactive {
                                selectedTextColor = .black
                            } else {
                                selectedTextColor = .white
                            }
                        }
                    }
                    .onChange(of: controlActiveState) { state in
                        if state == .inactive {
                            if colorScheme == .light {
                                selectedTextColor = .black
                            }
                            selectedBackgroundColor = .secondary
                        } else {
                            if colorScheme == .light {
                                selectedTextColor = .white
                            }
                            selectedBackgroundColor = .accentColor
                        }
                    }
                    .onAppear {
                        if colorScheme == .dark {
                            selectedTextColor = .white
                        } else {
                            if controlActiveState == .inactive {
                                selectedTextColor = .black
                            } else {
                                selectedTextColor = .white
                            }
                        }
                    }
                }
                .background(SplitViewAccessor(sideCollapsed: $collapsed))
            }
            .sheet(isPresented: $addFolderPresented) {
                VStack {
                    HStack {
                        TextField(text: $newFolder, label: {Text("folder.textfield.name")})
                            .frame(height: 40)
                        Picker(selection: $selectedSymbol, label: Text("Icon")) {
                            ForEach(AppFolder.shared.icons, id: \.self) { icon in
                                Image(systemName: icon)
                            }
                        }.fixedSize()
                    }
                    HStack {
                        Spacer()
                        Button(NSLocalizedString("button.OK", comment: ""), action: {
                            foldersObject.addFolder(folder: newFolder, icon: selectedSymbol)
                            selectedSymbol = "folder"
                            addFolderPresented.toggle()
                        })
                        .disabled(newFolder.isEmpty)
                        .keyboardShortcut(.defaultAction)
                        Button(NSLocalizedString("button.Cancel", comment: ""), action: {
                            newFolder = ""
                            selectedSymbol = "folder"
                            addFolderPresented.toggle()
                        })
                        .keyboardShortcut(.cancelAction)
                    }
                }
                .padding()
                .frame(width: 600, height: 100)
                }

            .onAppear {
                self.selectedView = URLObserved.type == .source ? 2 : 1
            }
            .overlay {
                HStack {
                    if !collapsed {
                        Spacer()
                            .frame(width: navWidth)
                    }
                    ToastView()
                        .environmentObject(ToastVM.shared)
                        .environmentObject(InstallVM.shared)
                        .environmentObject(DownloadVM.shared)
                        .frame(width: collapsed || viewWidth < navWidth ? viewWidth : (viewWidth - navWidth))
                        .animation(.spring(), value: collapsed)
                }
            }
            .onChange(of: viewGeom.size) { newSize in
                viewWidth = newSize.width
            }
            .alert("alert.moveAppToApplications.title",
                   isPresented: $integrity.integrityOff) {
                Button("alert.moveAppToApplications.move", role: .cancel) {
                    integrity.moveToApps()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            } message: {
                Text("alert.moveAppToApplications.subtitle")
            }
            .sheet(isPresented: $isSigningSetupShown) {
                SignSetupView(isSigningSetupShown: $isSigningSetupShown)
            }
            .onChange(of: URLObserved.action) { _ in
                self.selectedView = URLObserved.type == .source ? 2 : self.selectedView
            }
            .sheet(isPresented: $keyCoverObserved.isKeyCoverUnlockingPromptShown) {
                KeyCoverUnlockingPrompt()
            }
        }
        .frame(minWidth: 675, minHeight: 330)
    }

    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

struct SplitViewAccessor: NSViewRepresentable {
    @Binding var sideCollapsed: Bool

    func makeNSView(context: Context) -> some NSView {
        let view = MyView()
        view.sideCollapsed = _sideCollapsed
        return view
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {}

    class MyView: NSView {
        var sideCollapsed: Binding<Bool>?
        weak private var controller: NSSplitViewController?
        private var observer: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            var sview = superview

            // Find split view through hierarchy
            // swiftlint:disable:next force_unwrapping
            while sview != nil, !sview!.isKind(of: NSSplitView.self) {
                sview = sview?.superview
            }
            guard let sview = sview as? NSSplitView else { return }

            controller = sview.delegate as? NSSplitViewController

            if let sideBar = controller?.splitViewItems.first {
                observer = sideBar.observe(\.isCollapsed, options: [.new]) { [weak self] _, change in
                    if let value = change.newValue {
                        self?.sideCollapsed?.wrappedValue = value
                    }
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    @State static var isSigningSetupShown = true

    static var previews: some View {
        MainView(isSigningSetupShown: $isSigningSetupShown)
            .environmentObject(InstallVM.shared)
            .environmentObject(AppsVM.shared)
            .environmentObject(StoreVM.shared)
            .environmentObject(AppIntegrity())
    }
}

struct AddFolderView: View {
    @State var newFolder = ""
    @Binding var addFolderSheet: Bool

    var body: some View {
        VStack {
            TextField(text: $newFolder, label: {Text("preferences.textfield.url")})
            Spacer()
                .frame(height: 20)
            HStack {
                Spacer()
                Button {
                    addFolderSheet.toggle()
                } label: {
                    Text("button.Cancel")
                }
                Button {
                    addFolderSheet.toggle()
                } label: {
                    Text("button.OK")
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 600, height: 100)
    }
}

struct Folder: Identifiable, Codable {
    var id: UUID  = UUID()
    var name: String
    var apps: [String]  = []
    var icon: String = "folder"

    init(name: String, icon: String) {
        self.name = name
        self.icon = icon
    }
}
